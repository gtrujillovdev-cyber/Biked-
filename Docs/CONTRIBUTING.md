# Guía de Contribución y Convenciones 🧑‍💻

Para mantener el proyecto **Biked** limpio y profesional, sigue estas reglas al desarrollar.

## 🛠 Convenciones de Swift & SwiftUI

- **Arquitectura**: Sigue estrictamente **MVVM**. No pongas lógica de negocio ni cálculos en las Views.
- **Gestión de Estado**: Usa el macro `@Observable` para los ViewModels. Usa `@State` solo para estados efímeros de la UI (ej. si un botón está presionado).
- **Componentes**: Si una vista crece más de 50 líneas, extrae sub-vistas pequeñas y descriptivas.
- **Estilo**: Usa **AppTheme** para todos los colores, fuentes y gradientes. Evita usar `Color.red` o hexágonos directamente en el código de la vista.

---

## 🕷 Desarrollo de Scrapers (Python)

- **BaseScraper**: Hereda siempre de la clase base en `base_scraper.py` para reutilizar la lógica de Supabase y headers.
- **Anti-Blocking**: Si una web usa Next.js, intenta reconstruir el estado desde el JSON de la página antes de atacar una API privada.
- **Cortesía**: Incluye `time.sleep()` entre peticiones para no saturar los servidores de las marcas.

---

## 🗄 Estructura de Archivos

- `Biked/Biked/Data/Scrapers/`: Scripts de Python para extracción.
- `Biked/Biked/Data/Database/`: Scripts SQL para la base de datos.
- `Biked/Biked/Services/`: Clientes de API y Supabase.
- `Biked/Biked/ViewModels/`: Lógica de negocio y búsqueda.
- `Biked/Biked/Views/`: Interfaces de usuario.

---

## 🚀 Proceso de Pull Request

1. Asegúrate de que los scrapers suben los datos correctamente a Supabase.
2. Verifica que `SearchView.swift` y `SearchViewModel.swift` compilan sin errores de "exhaustive switch" o llaves sueltas.
3. Actualiza la vista `bikes_view.sql` si has añadido columnas nuevas a la base de datos.
