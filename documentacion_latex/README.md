# Proyecto LaTeX — FitLabs TFG

Este directorio contiene la documentación completa del Trabajo de Final de Ciclo **FitLabs** en formato LaTeX, lista para importar en **Overleaf** o compilar localmente.

## Estructura

```
documentacion_latex/
├── main.tex                          ← Archivo principal (compilar este)
├── bibliografia.bib                  ← Referencias bibliográficas (APA)
├── imagenes/                         ← Carpeta para imágenes (ver abajo)
└── capitulos/
    ├── 03_sector_productivo.tex
    ├── 04_introduccion.tex
    ├── 05_estado_del_arte.tex
    ├── 06_metodologia.tex
    ├── 07_tecnologias.tex            ← Incluye "Propuesta inicial vs final"
    ├── 08_viabilidad.tex
    ├── 09_planificacion.tex          ← Diagrama de Gantt + DAFO
    ├── 10_analisis.tex               ← Tablas RF/RNF + Esquema BD
    ├── 11_diseno.tex                 ← Pantallas + decisiones de diseño
    ├── 12_pruebas.tex
    ├── 13_plan_ejecucion.tex
    ├── 14_seguimiento.tex
    ├── 15_conclusiones.tex
    ├── 16_vias_futuras.tex
    ├── anexo_instalacion.tex
    └── anexo_usuario.tex
```

## Cómo usar en Overleaf

1. Crea un nuevo proyecto en [Overleaf](https://overleaf.com).
2. Sube todos los archivos de esta carpeta manteniendo la estructura de directorios.
3. Establece `main.tex` como el documento principal.
4. Compila con **pdfLaTeX** (si usas biber para la bibliografía, compila: pdfLaTeX → Biber → pdfLaTeX × 2).

## Imágenes necesarias

Guarda las siguientes imágenes en la carpeta `imagenes/`:

| Archivo | Descripción |
|---|---|
| `logo_fitlabs.png` | Logo de FitLabs para la portada |
| `diagrama_er.png` | Diagrama ER (ya está en `documentacion/base_de_datos/`) |
| `diagrama_arquitectura.png` | Diagrama de arquitectura (crear con draw.io) |
| `flujo_autenticacion.png` | Diagrama de flujo del proceso de login |
| `pantalla_login.png` | Captura de la pantalla de login |
| `pantalla_registro.png` | Captura de la pantalla de registro |
| `pantalla_resumen.png` | Captura del Resumen del Día |
| `pantalla_detalle_cliente.png` | Captura del Detalle de Cliente |
| `pantalla_crear_rutina.png` | Captura de Crear Rutina |
| `pantalla_mensajes.png` | Captura de la pantalla de Mensajes |

Puedes usar las capturas de pantalla del Figma adjunto (`png` del proyecto) como fuente.

## Apartados que requieren completar manualmente

Los siguientes bloques están marcados con `% TODO:` en los archivos `.tex`:

- **Cap. 3**: Ampliar con estadísticas del sector fitness-tech.
- **Cap. 5**: Completar datos estadísticos (Statista) y confirmar la API de ejercicios elegida.
- **Cap. 7** (`07_tecnologias.tex`): Completar la sección "Propuesta inicial" con los detalles reales de vuestra intención original.
- **Cap. 10**: Añadir los diagramas de arquitectura y flujo de autenticación como imágenes.
- **Cap. 11**: Insertar las capturas de pantalla reales de la aplicación.

## Notas de formato

- Fuente: Helvetica (≈ Arial) mediante el paquete `helvet`.
- Interlineado: 1,5 (paquete `setspace`).
- Márgenes: 2,5 cm en todos los lados.
- Numeración: romanos para portada/índice, arábigos desde el primer capítulo.
- Encabezado: título del proyecto y nombre de autores en todas las páginas.
