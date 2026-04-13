import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/core/shared_widgets.dart';

class DetalleClienteScreen extends StatelessWidget {
  const DetalleClienteScreen({super.key});

  // --- PALETA DE COLORES ---
  final Color _bgTop = const Color(0xFF2E2648);
  final Color _bgBottom = const Color(0xFF1A1625);
  final Color _accentLila = const Color(0xFFAEA6E8);
  final Color _cardSummaryBg = const Color(0xFF3E3666);
  final Color _cardGraphBg = const Color(0xFF2B253F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, const Color(0xFF241E32), _bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- CABECERA MODERNA ---
                _buildModernHeader(context),

                const SizedBox(height: 25),

                // --- CONTENIDO PRINCIPAL ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de Stats
                      _buildSummaryCard(),

                      const SizedBox(height: 30),

                      // --- PROGRESO DE PESO ---
                      const Text(
                        "Progreso de peso:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildWeightProgressCard(),

                      const SizedBox(height: 30),

                      // --- SESIONES PASADAS ---
                      const Text(
                        "Sesiones Pasadas",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Lista de sesiones
                      _buildSessionItem(
                        title: "Sesión Espalda - Pull",
                        dateOrTime: "Ayer",
                        rating: 4,
                        isLast: false,
                      ),
                      _buildSessionItem(
                        title: "Sesión cardio - HIIT",
                        dateOrTime: "11 : 00 - 11 : 30",
                        rating: 3,
                        isLast: false,
                      ),
                      _buildSessionItem(
                        title: "Sesión entrenamiento - Torso 1:2",
                        dateOrTime: "12 : 00 - 13 : 00",
                        rating: 5,
                        isLast: true,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGETS
  // --------------------------------------------------------------------------

  // *** HEADER MODERNO (El que te gustó) ***
  Widget _buildModernHeader(BuildContext context) {
    return Column(
      children: [
        // 1. Barra superior
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Perfil de Cliente",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Avatar Grande
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _accentLila.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: const Image(
            image: AssetImage('assets/images/imagenPerfil.png'),
            width: 100,
            height: 100,
          ),
        ),

        const SizedBox(height: 15),

        // 3. Info Cliente
        const Text(
          "Juan Ruíz Marín",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _accentLila.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accentLila.withValues(alpha: 0.5)),
          ),
          child: Text(
            "Cliente Activo",
            style: TextStyle(
              color: _accentLila,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 4. Caja de Objetivo
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                "OBJETIVO PRINCIPAL",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Subida de peso y ganancia de masa muscular",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: _cardSummaryBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem("22.9", "IMC", isBoldValue: true),
          Container(width: 1, height: 35, color: Colors.white12),
          _buildSummaryItem("Activa", "Suscripción"),
          Container(width: 1, height: 35, color: Colors.white12),
          _buildSummaryItem("28", "Sesiones"),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String value,
    String label, {
    bool isBoldValue = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  // --- TARJETA DE GRÁFICO MEJORADA ---
  Widget _buildWeightProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardGraphBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Info Texto (Izquierda)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWeightInfo("Mes pasado:", "68.5 kg"),
                const SizedBox(height: 15),
                _buildWeightInfo("Este mes", "70 kg", highlight: true),
                const SizedBox(
                  height: 30,
                ), // Más espacio para alinear con la gráfica
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Ver detalles",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Gráfico con Ejes (Derecha)
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 150, // Un poco más alto para que quepan los números
              child: CustomPaint(
                painter: DetailedLineChartPainter(lineColor: _accentLila),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInfo(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: highlight ? 22 : 16,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionItem({
    required String title,
    required String dateOrTime,
    required int rating,
    required bool isLast,
  }) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFD5D0FF),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        dateOrTime,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            "Rendimiento: ",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                          _buildStars(rating),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: const DashedDivider(),
          ),
      ],
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.white,
            size: 14,
          ),
        );
      }),
    );
  }
}

// --------------------------------------------------------------------------
// CLASES DE UTILIDAD
// --------------------------------------------------------------------------

class DetailedLineChartPainter extends CustomPainter {
  final Color lineColor;
  DetailedLineChartPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 25.0; // Espacio para números izq
    final double bottomPadding = 20.0; // Espacio para meses abajo

    // Área real de dibujo de la línea
    final double graphWidth = size.width - leftPadding;
    final double graphHeight = size.height - bottomPadding;

    // 1. DIBUJAR EJES (Líneas sutiles)
    final paintAxis = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;

    // Eje Y (Vertical)
    canvas.drawLine(
      Offset(leftPadding, 0),
      Offset(leftPadding, graphHeight),
      paintAxis,
    );
    // Eje X (Horizontal)
    canvas.drawLine(
      Offset(leftPadding, graphHeight),
      Offset(size.width, graphHeight),
      paintAxis,
    );

    // 2. DIBUJAR TEXTOS EJE Y (Pesos)
    _drawText(canvas, "72kg", Offset(0, 0));
    _drawText(canvas, "66kg", Offset(0, graphHeight / 2 - 5));
    _drawText(canvas, "60kg", Offset(0, graphHeight - 10));

    // 3. DIBUJAR TEXTOS EJE X (Meses)
    final List<String> months = ["Ene", "Feb", "Mar", "Abr"];
    double stepX = graphWidth / (months.length - 1);

    for (int i = 0; i < months.length; i++) {
      double xPos = leftPadding + (stepX * i);
      // Ajustamos un poco para centrar el texto
      _drawText(canvas, months[i], Offset(xPos - 10, size.height - 12));
    }

    // 4. DIBUJAR LA LÍNEA DE DATOS
    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Puntos simulados relativos al área del gráfico
    // (0,0) de la línea es (leftPadding, graphHeight)
    // Coordenada Y se invierte (0 es arriba)

    path.moveTo(leftPadding, graphHeight * 0.8); // Punto 1 (Ene)
    path.cubicTo(
      leftPadding + (stepX * 0.5),
      graphHeight * 0.9, // Control 1
      leftPadding + (stepX * 1.5),
      graphHeight * 0.5, // Control 2
      leftPadding + (stepX * 2.0),
      graphHeight * 0.4, // Punto (Mar)
    );
    path.cubicTo(
      leftPadding + (stepX * 2.5),
      graphHeight * 0.3,
      leftPadding + (stepX * 2.8),
      graphHeight * 0.1,
      leftPadding + (stepX * 3.0),
      graphHeight * 0.1, // Punto final (Abr - Arriba)
    );

    canvas.drawPath(path, paintLine);

    // Puntos decorativos en los extremos
    final paintDot = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(leftPadding, graphHeight * 0.8),
      3,
      paintDot,
    ); // Inicio
    canvas.drawCircle(
      Offset(leftPadding + (stepX * 3.0), graphHeight * 0.1),
      4,
      paintDot,
    ); // Final
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 9,
        fontWeight: FontWeight.w500,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
