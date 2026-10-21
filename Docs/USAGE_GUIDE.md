# Guía de Uso 🛠️

Esta guía detalla el funcionamiento de las características de **Biked** y la operativa de mantenimiento de datos.

---

## 1. Uso de la App iOS

### Búsqueda Biométrica Inteligente (Recomendada)
1. En la pestaña **Buscar**, selecciona la disciplina (*Carretera* o *Triatlón/TT*).
2. Mantén activo el modo **Biométrico**.
3. Selecciona tu **Estilo de Posición / Postura**:
   - 🔥 **Aero / Racing**: Posición baja y alargada para máxima penetración aerodinámica.
   - 🚴 **Equilibrada / Sport**: Polivalente para rendimiento y confort.
   - 💚 **Gran Fondo / Confort**: Posición más erguida para tiradas largas y confort lumbar.
4. Introduce tu **Altura** y **Entrepierna**. Opcionalmente, despliega *Medidas Avanzadas* para indicar tronco y brazo.
5. Observa la previsualización de tu **Geometría Estimada** en tiempo real.
6. Pulsa **"Buscar Bicicletas"**: el motor calculará las tallas con menor distancia euclidiana respecto a tu diana morfológica.

### Prescripción Biomecánica y Tarjeta Social
1. Al pulsar sobre cualquier bicicleta recomendada, verás la tarjeta de **Diagnóstico de Ajuste Biomecánico**:
   - **Porcentaje de Compatibilidad**: Ajuste *Óptimo* ($\le 8\text{ mm}$), *Compatible* ($\le 20\text{ mm}$) o *Ajuste Exigente* ($> 20\text{ mm}$).
   - **Configuración de Cockpit**: Cantidad de espaciadores sugerida (en múltiplos de 5mm) y longitud recomendada de potencia.
   - **Ratio STR**: Categorización de agresividad del cuadro.
2. Tienes dos opciones de compartición:
   - 📲 **"Exportar Tarjeta Historia (IG / WhatsApp)"**: Renderiza una tarjeta vertical en alta resolución (1080x1920) con fondo de carbono stealth, acentos de neón, foto de estudio recortada y radar de métricas, lista para publicar en tus historias de Instagram o enviar por WhatsApp.
   - 📋 **"Compartir Resumen en Texto"**: Genera un informe detallado en texto plano para biomecánicos o apps de mensajería.

### Comparador de Geometría Cara a Cara y Visualizador Vectorial CAD
1. Desde la vista de detalle de cualquier bicicleta o desde la pestaña **Favoritos** (con al menos 2 bicicletas guardadas), pulsa **"Comparar"**.
2. Selecciona los dos modelos y tallas que desees contrastar.
3. Elige entre los modos de visualización:
   - **Todo**: Resumen general y tabla.
   - **Diagrama (CAD Vectorial)**: Superpone los esquemas de ambos cuadros con pedalier alineado en el origen $(0,0)$. El cuadro A en Cian Neón y el cuadro B en Magenta Neón muestran visualmente la variación de Stack y Reach con líneas de cota $\Delta$.
   - **Tabla**: Comparativa numérica con deltas milimétricos en verde, cian o naranja.

### Alternancia de Unidades (Métrico / Imperial)
1. Toca el icono de engranaje en la barra superior de **Buscar**.
2. Cambia entre **Métrico** (cm, mm) e **Imperial** (in).
3. Todas las medidas ingresadas se convertirán y sincronizarán matemáticamente sin romper los cálculos.

### Explorar y Actualizar Catálogo
1. Ve a la pestaña **Explorar** para navegar por todas las marcas y modelos.
2. Desliza hacia abajo (*pull-to-refresh*) para forzar una sincronización con Supabase y descargar las últimas actualizaciones.

---

## 2. Actualización de Datos y Scrapers

Para extraer modelos recientes de los fabricantes oficiales:

1. Asegúrate de tener configurado tu archivo `.env` con la clave `SUPABASE_SERVICE_ROLE_KEY`:
   ```bash
   cd Biked/Biked/Data
   source venv/bin/activate
   ```
2. Ejecuta el orquestador de scrapers:
   ```bash
   python run_scrapers.py
   ```
3. El proceso:
   - Extraerá los modelos de **Specialized**, **Trek** y **Canyon**.
   - Subirá o actualizará las marcas, modelos y geometrías.
   - Descargará y subirá las imágenes al bucket de almacenamiento de Supabase.

---

## 3. Mantenimiento y Verificación

- Para validar que todos los cálculos matemáticos y la base de datos local están en perfecto estado tras una actualización:
  ```bash
  swift Biked/BikedTests/BikedTests.swift
  ```
- Si modificas el esquema en Supabase, re-ejecuta `Biked/Biked/Data/Database/bikes_view.sql` en el SQL Editor para actualizar la vista de la API.
