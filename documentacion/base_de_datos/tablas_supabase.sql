CREATE TABLE perfiles (
  id UUID PRIMARY KEY,
  role VARCHAR(50) NOT NULL,
  username VARCHAR(255) UNIQUE NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clientes_entrenador (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rutinas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
  assigned_client_id UUID REFERENCES perfiles(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ejercicios_rutina (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_rutina UUID NOT NULL,
  id_ejercicio_externo TEXT NOT NULL,
  serie INT NOT NULL,
  repeticiones INT,
  peso DECIMAL(10, 2),
  duracion INT,
  descanso INT,
  orden INT NOT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_rutina) REFERENCES rutinas(id) ON DELETE CASCADE
);

CREATE TABLE chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario1 UUID NOT NULL,
  id_usuario2 UUID NOT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario1) REFERENCES perfiles(id) ON DELETE CASCADE,
  FOREIGN KEY (id_usuario2) REFERENCES perfiles(id) ON DELETE CASCADE
);

CREATE TABLE mensajes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_chat UUID NOT NULL,
  id_remitente UUID NOT NULL,
  contenido TEXT NOT NULL,
  leido BOOLEAN DEFAULT FALSE,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_chat) REFERENCES chats(id) ON DELETE CASCADE,
  FOREIGN KEY (id_remitente) REFERENCES perfiles(id) ON DELETE CASCADE
);

CREATE TABLE seguidores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario UUID NOT NULL,
  id_seguidor UUID NOT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_usuario, id_seguidor),
  FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE,
  FOREIGN KEY (id_seguidor) REFERENCES perfiles(id) ON DELETE CASCADE
);

CREATE TABLE likes_rutina (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_rutina UUID NOT NULL,
  id_usuario UUID NOT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_rutina, id_usuario),
  FOREIGN KEY (id_rutina) REFERENCES rutinas(id) ON DELETE CASCADE,
  FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE
);

CREATE TABLE comentarios_rutina (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_rutina UUID NOT NULL,
  id_usuario UUID NOT NULL,
  contenido TEXT NOT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_rutina) REFERENCES rutinas(id) ON DELETE CASCADE,
  FOREIGN KEY (id_usuario) REFERENCES perfiles(id) ON DELETE CASCADE
);

-- Habilitar RLS
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes_entrenador ENABLE ROW LEVEL SECURITY;
ALTER TABLE rutinas ENABLE ROW LEVEL SECURITY;
ALTER TABLE ejercicios_rutina ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE seguidores ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes_rutina ENABLE ROW LEVEL SECURITY;
ALTER TABLE comentarios_rutina ENABLE ROW LEVEL SECURITY;
