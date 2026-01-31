import Foundation
import AuthenticationServices
import Security

class GoogleAuthService: NSObject, ObservableObject {
    static let shared = GoogleAuthService()

    // MARK: - Published State
    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var isAuthenticating = false
    @Published var error: String?

    // MARK: - OAuth Configuration
    private var clientId: String {
        SettingsManager.shared.settings.googleClientId
    }
    // Use reverse DNS custom scheme - ASWebAuthenticationSession handles this automatically
    private var redirectUri: String {
        // Format: com.googleusercontent.apps.{CLIENT_ID_PREFIX}:/oauth2callback
        // Extract the part before .apps.googleusercontent.com
        let parts = clientId.components(separatedBy: ".apps.googleusercontent.com")
        if let prefix = parts.first, !prefix.isEmpty {
            return "com.googleusercontent.apps.\(prefix):/oauth2callback"
        }
        return "com.dodocount:/oauth2callback"
    }

    private var callbackScheme: String {
        // Extract scheme from redirect URI
        let parts = clientId.components(separatedBy: ".apps.googleusercontent.com")
        if let prefix = parts.first, !prefix.isEmpty {
            return "com.googleusercontent.apps.\(prefix)"
        }
        return "com.dodocount"
    }

    private let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenEndpoint = "https://oauth2.googleapis.com/token"

    // Scopes needed for GA4 and Search Console
    private let scopes = [
        "https://www.googleapis.com/auth/analytics.readonly",
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/webmasters.readonly"
    ]

    // MARK: - Token Storage Keys
    private let accessTokenKey = "com.dodocount.accessToken"
    private let refreshTokenKey = "com.dodocount.refreshToken"
    private let tokenExpiryKey = "com.dodocount.tokenExpiry"

    // MARK: - Tokens
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?

    private var authSession: ASWebAuthenticationSession?

    override init() {
        super.init()
        loadTokensFromKeychain()
    }

    // MARK: - Public Methods

    /// Start the OAuth sign-in flow
    func signIn() {
        guard !isAuthenticating else { return }

        // Check if client ID is configured
        guard !clientId.isEmpty else {
            error = "Please enter your Google Client ID in Settings"
            return
        }

        isAuthenticating = true
        error = nil

        // Build authorization URL
        guard var components = URLComponents(string: authorizationEndpoint) else {
            self.error = "Failed to build authorization URL"
            self.isAuthenticating = false
            return
        }
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authURL = components.url else {
            self.error = "Failed to build authorization URL"
            self.isAuthenticating = false
            return
        }

        // Create authentication session
        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                self?.handleAuthCallback(callbackURL: callbackURL, error: error)
            }
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }

    /// Sign out and clear tokens
    func signOut() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        userEmail = nil
        isAuthenticated = false

        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)

        NotificationCenter.default.post(name: NSNotification.Name("GoogleAuthStateChanged"), object: nil)
    }

    /// Get a valid access token, refreshing if needed
    func getValidAccessToken() async throws -> String {
        // Check if we have a valid token (with 60 second buffer before expiry)
        if let token = accessToken, let expiry = tokenExpiry, expiry > Date().addingTimeInterval(60) {
            return token
        }

        // Try to refresh
        guard let refresh = refreshToken else {
            await MainActor.run { self.isAuthenticated = false }
            throw AuthError.notAuthenticated
        }

        do {
            try await refreshAccessToken(refreshToken: refresh)
        } catch {
            // If refresh fails, sign out and require re-authentication
            await MainActor.run {
                self.signOut()
            }
            throw AuthError.tokenRefreshFailed
        }

        guard let token = accessToken else {
            throw AuthError.tokenRefreshFailed
        }

        return token
    }

    // MARK: - Private Methods

    private func handleAuthCallback(callbackURL: URL?, error: Error?) {
        isAuthenticating = false

        if let error = error {
            if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                self.error = nil // User cancelled, not an error
            } else {
                self.error = error.localizedDescription
            }
            return
        }

        guard let callbackURL = callbackURL,
              let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            self.error = "Failed to get authorization code"
            return
        }

        // Exchange code for tokens
        Task {
            do {
                try await exchangeCodeForTokens(code: code)
                await MainActor.run {
                    self.isAuthenticated = true
                    NotificationCenter.default.post(name: NSNotification.Name("GoogleAuthStateChanged"), object: nil)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    private func exchangeCodeForTokens(code: String) async throws {
        guard let url = URL(string: tokenEndpoint) else {
            throw AuthError.tokenExchangeFailed
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "code": code,
            "client_id": clientId,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        await MainActor.run {
            self.accessToken = tokenResponse.accessToken
            self.refreshToken = tokenResponse.refreshToken ?? self.refreshToken
            self.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

            // Save to keychain
            self.saveToKeychain(key: self.accessTokenKey, value: tokenResponse.accessToken)
            if let refresh = tokenResponse.refreshToken {
                self.saveToKeychain(key: self.refreshTokenKey, value: refresh)
            }
            UserDefaults.standard.set(self.tokenExpiry?.timeIntervalSince1970, forKey: self.tokenExpiryKey)
        }

        // Fetch user info
        try await fetchUserInfo()
    }

    private func refreshAccessToken(refreshToken: String) async throws {
        guard let url = URL(string: tokenEndpoint) else {
            throw AuthError.tokenRefreshFailed
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "refresh_token": refreshToken,
            "client_id": clientId,
            "grant_type": "refresh_token"
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.tokenRefreshFailed
        }

        // Handle non-200 responses
        if httpResponse.statusCode != 200 {
            // Try to parse error from Google
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDesc = errorJson["error_description"] as? String {
                // Google returned an error - likely token revoked or expired
                if errorDesc.contains("revoked") || errorDesc.contains("expired") || errorDesc.contains("invalid") {
                    throw AuthError.tokenRevoked
                }
            }
            throw AuthError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        await MainActor.run {
            self.accessToken = tokenResponse.accessToken
            self.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

            self.saveToKeychain(key: self.accessTokenKey, value: tokenResponse.accessToken)
            UserDefaults.standard.set(self.tokenExpiry?.timeIntervalSince1970, forKey: self.tokenExpiryKey)
        }
    }

    private func fetchUserInfo() async throws {
        guard let token = accessToken else { return }

        guard let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let userInfo = try JSONDecoder().decode(UserInfo.self, from: data)

        await MainActor.run {
            self.userEmail = userInfo.email
        }
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.dodocount",
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.dodocount",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.dodocount"
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func loadTokensFromKeychain() {
        accessToken = loadFromKeychain(key: accessTokenKey)
        refreshToken = loadFromKeychain(key: refreshTokenKey)

        if let expiryInterval = UserDefaults.standard.object(forKey: tokenExpiryKey) as? TimeInterval {
            tokenExpiry = Date(timeIntervalSince1970: expiryInterval)
        }

        if accessToken != nil && refreshToken != nil {
            isAuthenticated = true

            // Fetch user info if we have a token
            Task {
                try? await fetchUserInfo()
            }
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension GoogleAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApp.windows.first ?? ASPresentationAnchor()
    }
}

// MARK: - Models
struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct UserInfo: Codable {
    let email: String
    let name: String?
    let picture: String?
}

// MARK: - Errors
enum AuthError: LocalizedError {
    case notAuthenticated
    case tokenExchangeFailed
    case tokenRefreshFailed
    case tokenRevoked

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for tokens."
        case .tokenRefreshFailed:
            return "Session expired. Please sign in again."
        case .tokenRevoked:
            return "Access was revoked. Please sign in again."
        }
    }
}
