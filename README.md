# Biked - Bike Geometry Finder 🚲

**Biked** es una aplicación iOS de primer nivel diseñada para ciclistas y biomecánicos que buscan la bicicleta ideal basándose en la ciencia de la geometría. Permite explorar un catálogo 100% curado con fotos de estudio estandarizadas, comparar modelos superponiendo planos vectoriales CAD cara a cara, obtener prescripciones biomecánicas de cockpit (espaciadores y longitud de potencia) y exportar tarjetas de diagnóstico en alta resolución para Instagram Stories y WhatsApp.

---

## ✨ Características Principales

- 📐 **Motor Biomecánico de Regresión**: Algoritmo que calcula el Stack y Reach diana según altura, entrepierna, tronco y estilo postural (*Aero/Racing*, *Equilibrada/Sport*, *Gran Fondo/Confort*).
- 🖼️ **Catálogo de Estudio 100% Armonizado**: Las **56 bicicletas del catálogo** cuentan con activos fotográficos estandarizados en formato panorámico **16:9 (1600x900 px)** con canal alfa transparente, eliminación de fondos planos y efectos de iluminación de foco y sombra en suelo.
- 📐 **Superposición Vectorial CAD (Wireframe Overlay)**: Visualización interactiva que superpone el cuadro A (Cian Neón) y cuadro B (Magenta Neón) compartiendo el origen común del pedalier (Bottom Bracket $(0,0)$), trazando los deltas de Stack y Reach ($\Delta S$, $\Delta R$).
- 📲 **Exportación de Tarjeta Historia (Instagram / WhatsApp)**: Generación nativa en alta resolución mediante SwiftUI `ImageRenderer` (escala 3.0x / 1080x1920) para compartir el informe biomecánico en redes sociales.
- 🔗 **Enlaces Oficiales 100% Verificados**: Cada bicicleta incluye acceso directo a la página web oficial del fabricante para consultar disponibilidad y especificaciones.
- 📋 **Prescripción de Puesto de Conducción (Cockpit)**: Cálculo automático de espaciadores recomendados (en saltos de 5mm), longitud de potencia sugerida y ratio Stack-to-Reach (STR).
- ⚖️ **Comparador de Geometría Cara a Cara**: Comparativa milimétrica con modos *Todo*, *Diagrama Vectorial* y *Tabla Detallada*.
- 🔄 **Soporte Bimodal Métrico e Imperial**: Alternancia instantánea entre mm/cm y pulgadas con sincronización matemática bidireccional en tiempo real.
- 🌗 **Control de Apariencia**: Selector de tema en ajustes (*Oscuro*, *Claro*, *Sistema*).
- 🛡️ **Seguridad Blindada (Supabase RLS)**: Acceso público de solo lectura (`SELECT`) protegido por Row Level Security; operaciones de administración restringidas a `service_role`.
- ⚡ **Arquitectura Reactiva y Concurrente**: Modelo MVVM en SwiftUI con macros `@Observable`, ViewModels en `@MainActor` y `actor BikeAPIService` libre de Data Races.
- 💾 **Estrategia Local-First Fiable**: Cero latencia local durante el diseño de interfaz y activos, con sincronización cloud desacoplable mediante flag.
- 🧪 **Suite de Pruebas Automatizadas**: 18 tests unitarios que verifican fórmulas biomecánicas, conversiones métricas, consistencia del catálogo y cobertura fotográfica del 100%.

---

## 📖 Documentación del Proyecto

1. 🚀 **[Guía de Inicio Rápido](Docs/SETUP_GUIDE.md)**: Configuración de entorno, Xcode y ejecución de tests.
2. 🏗️ **[Arquitectura Técnica](Docs/ARCHITECTURE.md)**: Explicación de la arquitectura MVVM, aislamiento de concurrencia, esquemas y pipeline.
3. 🛠️ **[Guía de Uso](Docs/USAGE_GUIDE.md)**: Modos de búsqueda, comparador con wireframe, prescripción y exportación social.
4. 🧑‍💻 **[Guía de Contribución](Docs/CONTRIBUTING.md)**: Convenciones de código y flujo de desarrollo.

---

## 🚀 Instalación y Verificación

1. Clona el repositorio:
   ```bash
   git clone https://github.com/gtrujillovdev-cyber/Biked-.git
   cd Biked-
   ```
2. Ejecuta la suite de pruebas unitarias:
   ```bash
   swift -module-cache-path ./build/ModuleCache Biked/BikedTests/BikedTests.swift
   ```
3. Abre el proyecto en Xcode:
   ```bash
   open Biked/Biked.xcodeproj
   ```
4. ¡Compila y disfruta de la experiencia Biked!

---
*Desarrollado con ❤️ y rigor biomecánico para la comunidad ciclista.*
