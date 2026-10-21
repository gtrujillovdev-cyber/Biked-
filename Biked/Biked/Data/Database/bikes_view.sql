-- 1. Enable Row Level Security
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE models ENABLE ROW LEVEL SECURITY;
ALTER TABLE geometries ENABLE ROW LEVEL SECURITY;
ALTER TABLE builds ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS contributions ENABLE ROW LEVEL SECURITY;

-- 2. Create Public Read-Only Policies for App Clients
-- Permite lectura pública anónima (SELECT) para el catálogo de bicicletas
DROP POLICY IF EXISTS "Public Access Select" ON brands;
DROP POLICY IF EXISTS "Public Access Select" ON models;
DROP POLICY IF EXISTS "Public Access Select" ON geometries;
DROP POLICY IF EXISTS "Public Access Select" ON builds;

CREATE POLICY "Public Access Select" ON brands FOR SELECT USING (true);
CREATE POLICY "Public Access Select" ON models FOR SELECT USING (true);
CREATE POLICY "Public Access Select" ON geometries FOR SELECT USING (true);
CREATE POLICY "Public Access Select" ON builds FOR SELECT USING (true);

-- Eliminar políticas públicas permisivas de INSERT y UPDATE para prevenir manipulación no autorizada.
-- NOTA DE SEGURIDAD: La clave anon (pública en la app) NUNCA debe tener permisos de escritura.
-- Los scripts de scraping y administración usan la clave privada SUPABASE_SERVICE_ROLE_KEY
-- que omite RLS de forma segura en el servidor.
DROP POLICY IF EXISTS "Allow Public Insert" ON brands;
DROP POLICY IF EXISTS "Allow Public Insert" ON models;
DROP POLICY IF EXISTS "Allow Public Insert" ON geometries;
DROP POLICY IF EXISTS "Allow Public Insert" ON builds;

DROP POLICY IF EXISTS "Allow Public Update" ON brands;
DROP POLICY IF EXISTS "Allow Public Update" ON models;
DROP POLICY IF EXISTS "Allow Public Update" ON geometries;
DROP POLICY IF EXISTS "Allow Public Update" ON builds;

-- Opcional: Permitir a usuarios anónimos proponer contribuciones (siempre con estado PENDING)
DROP POLICY IF EXISTS "Allow Public Contribution Submission" ON contributions;
CREATE POLICY "Allow Public Contribution Submission" ON contributions
FOR INSERT TO public WITH CHECK (status = 'PENDING');

-- 3. STORAGE POLICIES
INSERT INTO storage.buckets (id, name, public) 
VALUES ('bike-images', 'bike-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Lectura pública de imágenes
DROP POLICY IF EXISTS "Allow Public Select" ON storage.objects;
CREATE POLICY "Allow Public Select" 
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'bike-images');

-- Eliminamos uploads públicos arbitrarios con la clave anónima.
-- Las subidas de imágenes de scrapers deben usar la service_role key.
DROP POLICY IF EXISTS "Allow Public Uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow Public Update" ON storage.objects;

-- 4. Create the Main View for the App
-- Esta vista agrega los datos relacionales en el formato JSON que espera el modelo Swift
CREATE OR REPLACE VIEW bikes_view AS
SELECT
    m.id::text AS id,
    b.name AS brand,
    m.name AS model,
    m.year AS year,
    m.discipline AS category,
    'High performance ' || m.discipline || ' bike from ' || b.name AS description,
    -- official_url viene del primer build que tenga official_buy_url; si ninguno, NULL
    (
        SELECT bu.official_buy_url
        FROM builds bu
        WHERE bu.model_id = m.id AND bu.official_buy_url IS NOT NULL
        LIMIT 1
    ) AS official_url,
    -- dateAdded como string 'YYYY-MM-DD' para que el DateFormatter de Swift lo parsee
    TO_CHAR(m.created_at, 'YYYY-MM-DD') AS "dateAdded",
    -- Geometría: array de objetos con las keys exactas que espera el modelo Geometry de Swift
    COALESCE(
        (
            SELECT json_agg(json_build_object(
                'size',     g.size_label,
                'stack_mm', g.stack_mm,
                'reach_mm', g.reach_mm
            ) ORDER BY g.stack_mm ASC)
            FROM geometries g
            WHERE g.model_id = m.id
        ),
        '[]'::json
    ) AS geometry,
    -- Builds: array con las keys exactas que espera BikeBuild de Swift
    COALESCE(
        (
            SELECT json_agg(json_build_object(
                'id',        bu.id::text,
                'name',      COALESCE(bu.name, 'Standard'),
                'color',     'Standard',
                'price_eur', COALESCE(bu.price_estimated, 0),
                -- Filtramos imagen NULL para no meter null en el array
                'images',    CASE
                                WHEN bu.image_url IS NOT NULL
                                THEN json_build_array(bu.image_url)
                                ELSE '[]'::json
                             END,
                'specs',     json_build_object(
                                'groupset',    COALESCE(bu.groupset, 'N/A'),
                                'wheelset',    COALESCE(bu.wheelset, 'N/A'),
                                'power_meter', 'None'
                             ),
                'inventory', json_build_object('All', 1)
            ))
            FROM builds bu
            WHERE bu.model_id = m.id
        ),
        '[]'::json
    ) AS builds
FROM models m
JOIN brands b ON m.brand_id = b.id;
