<p align="center">
  <img src="dodocount.png" alt="DodoCount" width="200" />
</p>

<h1 align="center">DodoCount</h1>

<p align="center">
  Una elegante aplicación de barra de menús de macOS para Google Analytics 4 y Search Console.
</p>

<p align="center">
  <img width="280" alt="Screenshot 1" src="https://github.com/user-attachments/assets/ee7dd7e5-9951-4157-94bb-29ccbf15edb6" />
  <img width="280" alt="Screenshot 2" src="https://github.com/user-attachments/assets/59f64d9e-98e0-425a-9f5d-2851a5bc7dc2" />
  <img width="280" alt="Screenshot 3" src="https://github.com/user-attachments/assets/0c583250-f83e-4da8-920a-d71761cc4ee7" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange" alt="Swift" />
  <img src="https://img.shields.io/badge/Licencia-MIT-green" alt="License" />
</p>

<p align="center">
  🌐 <strong>Traducciones:</strong> <a href="README.md">English</a> | <a href="README.tr.md">Türkçe</a> | <a href="README.de.md">Deutsch</a> | <a href="README.fr.md">Français</a>
</p>

## Características

- **Seguimiento de visitantes en tiempo real** - Ve los usuarios activos directamente en tu barra de menús
- **Integración con Google Analytics 4** - Soporte completo para propiedades GA4
- **Datos de Search Console** - Rastrea clics, impresiones, CTR y posición
- **Comparación Hoy vs Ayer** - Usuarios, sesiones, páginas vistas, tasa de rebote, duración
- **Resumen de 28 días** - Métricas extendidas con visualización de tendencias
- **Páginas populares y fuentes de tráfico** - Ve qué está funcionando
- **Múltiples propiedades** - Cambia fácilmente entre propiedades GA4
- **Hermoso tema oscuro** - Diseño glass morphism acorde a la estética de macOS
- **Compartir estadísticas** - Copia estadísticas rápidas, detalladas o en formato Slack
- **Alertas** - Notificaciones para picos de tráfico, caídas y logro de objetivos
- **Atajo global** - Acceso rápido con Cmd+Shift+G
- **Soporte multiidioma** - Inglés, Turco, Alemán, Francés, Español

## Requisitos

- macOS 14.0 o posterior
- Proyecto de Google Cloud con credenciales OAuth 2.0
- Propiedad de Google Analytics 4
- (Opcional) Sitio de Google Search Console

## Instalación

### Homebrew (Recomendado)

```bash
brew tap DodoApps/tap
brew install --cask dodocount
xattr -cr /Applications/DodoCount.app
```

### Descarga Manual

1. Descarga la última versión desde [Releases](https://github.com/DodoApps/dodocount/releases)
2. Mueve DodoCount.app a tu carpeta de Aplicaciones
3. Ejecuta `xattr -cr /Applications/DodoCount.app` para eliminar la cuarentena
4. Inicia DodoCount

## Configuración

### 1. Crear credenciales OAuth de Google Cloud

1. Ve a [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita las siguientes APIs:
   - Google Analytics Data API
   - Google Analytics Admin API
   - Google Search Console API
4. Crea credenciales OAuth 2.0:
   - Tipo de aplicación: **iOS** (requerido para apps de escritorio)
   - Bundle ID: `com.dodocount`
5. Copia tu ID de cliente

### 2. Configurar DodoCount

1. Haz clic en el icono de DodoCount en tu barra de menús
2. Haz clic en el icono de engranaje para abrir Ajustes
3. Pega tu ID de cliente en la sección "Google Cloud"
4. Haz clic en "Iniciar sesión" para autenticarte con Google
5. Selecciona tu propiedad GA4 del menú desplegable

## Uso

- **Clic izquierdo** en el icono de la barra de menús para abrir el panel
- **Clic derecho** para acciones rápidas (copiar estadísticas, actualizar, ajustes, salir)
- **Cmd+Shift+G** para mostrar/ocultar el panel desde cualquier lugar

## Compilar desde el código fuente

```bash
git clone https://github.com/DodoApps/dodocount.git
cd dodocount
open DodoCount.xcodeproj
```

Compila y ejecuta en Xcode (requiere Xcode 15.0+).

## Contribuir

¡Las contribuciones son bienvenidas! No dudes en enviar un Pull Request.

## Licencia

Licencia MIT - ver [LICENSE](LICENSE) para más detalles.

## Derechos de autor

© 2026 DodoApps

