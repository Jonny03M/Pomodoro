import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'resumen_diario_screen.dart';
import 'flashcard_screen.dart';
import 'main.dart';
import 'package:intl/date_symbol_data_local.dart';

class ResumenSemanalScreen extends StatefulWidget {
  const ResumenSemanalScreen({super.key});

  @override
  ResumenSemanalScreenState createState() => ResumenSemanalScreenState();
}

class ResumenSemanalScreenState extends State<ResumenSemanalScreen> {
  List<Tarea> _tareas = [];
  Map<String, int> tareasFinalizadasPorDia = {};
  Map<String, int> tareasPendientesPorDia = {};
  List<String> diasSemana = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _cargarTareas();
  }

  Future<void> _cargarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? tareasJson = prefs.getStringList('tareas');

    if (tareasJson != null) {
      List<Tarea> todasLasTareas =
          tareasJson.map((tarea) => Tarea.fromMap(jsonDecode(tarea))).toList();

      DateTime hoy = DateTime.now();
      DateTime semanaInicio = hoy.subtract(const Duration(days: 6));

      setState(() {
        _tareas = todasLasTareas.where((tarea) {
          DateTime fechaTarea =
              DateFormat('EEEE, d MMMM yyyy', 'es').parse(tarea.fechaCreacion);

          bool incluida = fechaTarea
                  .isAfter(semanaInicio.subtract(const Duration(seconds: 1))) &&
              fechaTarea.isBefore(hoy.add(const Duration(seconds: 1)));

          debugPrint(
              "Fecha de tarea: ${tarea.fechaCreacion}, Incluida en resumen semanal: $incluida");
          return incluida;
        }).toList();

        _procesarDatosGrafico();

        debugPrint(
            "Total de tareas cargadas en la última semana: ${_tareas.length}");
      });
    }
  }

  void _procesarDatosGrafico() {
    DateTime hoy = DateTime.now();
    tareasFinalizadasPorDia.clear();
    tareasPendientesPorDia.clear();
    diasSemana.clear();

    Set<String> diasUnicos = {};

    for (int i = 0; i <= 6; i++) {
      DateTime dia = hoy.subtract(Duration(days: i));
      String nombreDia = DateFormat('EEEE', 'es').format(dia);

      if (!diasUnicos.contains(nombreDia)) {
        diasSemana.insert(0, nombreDia);
        diasUnicos.add(nombreDia);
      }

      tareasFinalizadasPorDia[nombreDia] = _tareas
          .where((t) =>
              t.fechaCreacion ==
                  DateFormat('EEEE, d MMMM yyyy', 'es').format(dia) &&
              t.finalizada)
          .length;

      tareasPendientesPorDia[nombreDia] = _tareas
          .where((t) =>
              t.fechaCreacion ==
                  DateFormat('EEEE, d MMMM yyyy', 'es').format(dia) &&
              !t.finalizada)
          .length;
    }
  }

  Widget _crearGraficaDesempeno() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: const Text("Número de tareas",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(),
                      style: const TextStyle(fontSize: 12));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text("Días de la semana",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < diasSemana.length) {
                    return Text(diasSemana[index],
                        style: const TextStyle(fontSize: 12));
                  }
                  return const Text("");
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  diasSemana.length,
                  (index) => FlSpot(
                      index.toDouble(),
                      tareasFinalizadasPorDia[diasSemana[index]]?.toDouble() ??
                          0)),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(
                  diasSemana.length,
                  (index) => FlSpot(
                      index.toDouble(),
                      tareasPendientesPorDia[diasSemana[index]]?.toDouble() ??
                          0)),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crearListaTareas() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text("Tarea",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Center(
                        child: Text("Prioridad",
                            style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(
                    flex: 1,
                    child: Center(
                        child: Text("Finalizada",
                            style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _tareas.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_tareas[index].nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(_tareas[index].fechaCreacion,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            _tareas[index].prioridad,
                            style: TextStyle(
                              fontSize: 16,
                              color: _tareas[index].prioridad == "Alta"
                                  ? Colors.red
                                  : _tareas[index].prioridad == "Media"
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Icon(
                            _tareas[index].finalizada
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _tareas[index].finalizada
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 80,
            color: Colors.grey[300],
            child: Column(
              children: [
                const SizedBox(height: 30),
                IconButton(
                  icon: const Icon(Icons.home, size: 36, color: Colors.pink),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PomodoroScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 80,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  color: Colors.pink[200],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Resumen Semanal",
                        style: TextStyle(
                            color: Colors.pink,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.menu,
                            color: Colors.pink, size: 36),
                        onSelected: (String choice) {
                          if (choice == 'Resumen diario') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ResumenDiarioScreen()));
                          } else if (choice == 'Flashcards') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const FlashcardScreen()));
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            'Resumen diario',
                            'Flashcards',
                            'Resumen semanal'
                          ].map((String option) {
                            return PopupMenuItem<String>(
                              value: option,
                              child: Text(option,
                                  style: const TextStyle(color: Colors.pink)),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _crearListaTareas()),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: _crearGraficaDesempeno(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
