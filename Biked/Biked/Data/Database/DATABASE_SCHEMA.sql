-- Biked Database Schema (Supabase / PostgreSQL)

-- 1. Brands Table
CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    logo_url TEXT,
    website_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Bike Models Table
CREATE TABLE models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID REFERENCES brands(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    year INTEGER,
    discipline TEXT CHECK (discipline IN ('ROAD', 'TT', 'MTB', 'GRAVEL', 'OTHER')),
    external_id TEXT,      -- Slug para evitar duplicados (ej: 'trek-madone-slr')
    official_url TEXT,     -- URL de la página oficial del fabricante
    description TEXT,      -- Descripción de la bici (opcional)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(brand_id, name, year)
);

-- 3. Geometry Table (Per Size)
CREATE TABLE geometries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID REFERENCES models(id) ON DELETE CASCADE,
    size_label TEXT NOT NULL, -- e.g., "S", "54", "M"
    stack_mm DOUBLE PRECISION NOT NULL,
    reach_mm DOUBLE PRECISION NOT NULL,
    wheel_size TEXT DEFAULT '700c',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_id, size_label)
);

-- 4. Builds Table (Components & Images)
CREATE TABLE builds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID REFERENCES models(id) ON DELETE CASCADE,
    name TEXT, -- e.g., "Dura-Ace Di2", "Pro"
    groupset TEXT,
    wheelset TEXT,
    price_estimated DECIMAL,
    currency TEXT DEFAULT 'EUR',
    image_url TEXT, -- Link to Supabase Storage
    official_buy_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE, -- Human/AI check flag
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. User Contributions / Requests
CREATE TABLE contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID, -- If auth is enabled later
    brand_name TEXT,
    model_name TEXT,
    year INTEGER,
    source_url TEXT,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSED', 'REJECTED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Row Level Security (RLS) Configuration
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE models ENABLE ROW LEVEL SECURITY;
ALTER TABLE geometries ENABLE ROW LEVEL SECURITY;
ALTER TABLE builds ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;

-- Lectura pública para el catálogo
CREATE POLICY "Public Read Brands" ON brands FOR SELECT USING (true);
CREATE POLICY "Public Read Models" ON models FOR SELECT USING (true);
CREATE POLICY "Public Read Geometries" ON geometries FOR SELECT USING (true);
CREATE POLICY "Public Read Builds" ON builds FOR SELECT USING (true);

-- Envío anónimo de contribuciones (estado PENDING obligatorio)
CREATE POLICY "Public Insert Contributions" ON contributions FOR INSERT WITH CHECK (status = 'PENDING');

