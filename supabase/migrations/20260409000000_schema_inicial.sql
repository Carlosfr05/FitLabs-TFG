CREATE TABLE IF NOT EXISTS public.perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL,
  telefono TEXT,
  foto_url TEXT,
  rol TEXT NOT NULL DEFAULT 'entrenador' CHECK (rol IN ('entrenador','cliente')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Perfil propio" ON public.perfiles FOR ALL USING (auth.uid() = id);

CREATE TABLE IF NOT EXISTS public.clientes_entrenador (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entrenador_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
  cliente_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(entrenador_id, cliente_id)
);
ALTER TABLE public.clientes_entrenador ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ver mis clientes" ON public.clientes_entrenador FOR SELECT USING (auth.uid() = entrenador_id OR auth.uid() = cliente_id);

CREATE TABLE IF NOT EXISTS public.rutinas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creador_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
  cliente_id UUID REFERENCES public.perfiles(id),
  nombre TEXT NOT NULL,
  descripcion TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.rutinas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ver rutinas propias" ON public.rutinas FOR ALL USING (auth.uid() = creador_id OR auth.uid() = cliente_id);

CREATE TABLE IF NOT EXISTS public.ejercicios_rutina (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rutina_id UUID NOT NULL REFERENCES public.rutinas(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  series INTEGER DEFAULT 3,
  repeticiones INTEGER DEFAULT 10,
  peso NUMERIC,
  notas TEXT,
  orden INTEGER DEFAULT 0
);
ALTER TABLE public.ejercicios_rutina ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ver ejercicios" ON public.ejercicios_rutina FOR ALL
  USING (EXISTS (SELECT 1 FROM public.rutinas r WHERE r.id = rutina_id AND (r.creador_id = auth.uid() OR r.cliente_id = auth.uid())));

CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entrenador_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
  cliente_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(entrenador_id, cliente_id)
);
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ver mis chats" ON public.chats FOR ALL USING (auth.uid() = entrenador_id OR auth.uid() = cliente_id);

CREATE TABLE IF NOT EXISTS public.mensajes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  remitente_id UUID NOT NULL REFERENCES public.perfiles(id),
  contenido TEXT NOT NULL,
  leido BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.mensajes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ver mensajes" ON public.mensajes FOR ALL
  USING (EXISTS (SELECT 1 FROM public.chats c WHERE c.id = chat_id AND (c.entrenador_id = auth.uid() OR c.cliente_id = auth.uid())));