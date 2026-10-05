// Importaciones de paquetes necesarios en la aplicación.
import 'package:flutter/material.dart'; // Provee los widgets y temas para la interfaz gráfica.
import 'package:intl/intl.dart'; // Para formatear fechas de acuerdo a diferentes normas internacionales.
import 'package:intl/date_symbol_data_local.dart'; // Inicializa los datos de localización para el formateo de fechas.
import 'dart:convert'; // Permite la codificación y decodificación de datos en formato JSON.
import 'package:shared_preferences/shared_preferences.dart'; // Facilita el almacenamiento de datos de forma persistente en el dispositivo.
import 'flashcard_screen.dart'; // Pantalla para la funcionalidad de flashcards.
import 'main.dart'; // Importa elementos definidos en el archivo principal de la app.
import 'resumen_semanal_screen.dart'; // Pantalla para mostrar un resumen semanal.

/// Clase que modela una tarea en la aplicación.
class Tarea {
  /// El nombre o título de la tarea.
  String nombre;
  
  /// Representa la prioridad de la tarea (por ejemplo: 'Alta', 'Media', 'Baja').
  String prioridad;
  
  /// Indica si la tarea está finalizada (true) o no (false).
  bool finalizada;
  
  /// Almacena la fecha de creación de la tarea en formato de texto.
  String fechaCreacion;

  /// Constructor de la clase, que requiere 'nombre', 'prioridad' y 'fechaCreacion'.
  /// El parámetro 'finalizada' es opcional y, si no se especifica, se asume en `false`.
  Tarea({
    required this.nombre,
    required this.prioridad,
    this.finalizada = false,
    required this.fechaCreacion,
  });

  /// Convierte la instancia de [Tarea] a un [Map<String, dynamic>].
  /// Esto es útil para almacenar la tarea en bases de datos locales o para su conversión a JSON.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'prioridad': prioridad,
      'finalizada': finalizada,
      'fechaCreacion': fechaCreacion,
    };
  }

  /// Crea una instancia de [Tarea] a partir de un [Map].
  /// Se asignan valores predeterminados en caso de que alguna llave no exista en el [Map].
  /// En particular, si 'fechaCreacion' no está definido, se asigna la fecha actual formateada en español.
  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      nombre: map['nombre'] ?? '',
      prioridad: map['prioridad'] ?? 'Media',
      finalizada: map['finalizada'] ?? false,
      fechaCreacion: map['fechaCreacion'] ??
          DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
    );
  }
}

/// Pantalla que muestra el resumen diario de las tareas.
/// Es un [StatefulWidget] ya que su contenido puede cambiar en tiempo de ejecución.
class ResumenDiarioScreen extends StatefulWidget {
  const ResumenDiarioScreen({super.key});

  /// Crea el estado asociado a esta pantalla.
  @override
  ResumenDiarioScreenState createState() => ResumenDiarioScreenState();
}

class ResumenDiarioScreenState extends State<ResumenDiarioScreen> {
  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  List<Tarea> _tareas = [];

  Future<void> _guardarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 🔹 Recuperamos las tareas guardadas previamente
    List<String>? tareasJsonPrevias = prefs.getStringList('tareas') ?? [];
    List<Tarea> tareasPrevias = tareasJsonPrevias.map((t) => Tarea.fromMap(jsonDecode(t))).toList();

    // 🔹 Reemplazamos las tareas actualizadas dentro de la lista existente
    for (var tareaNueva in _tareas) {
      for (var i = 0; i < tareasPrevias.length; i++) {
        if (tareasPrevias[i].nombre == tareaNueva.nombre && tareasPrevias[i].fechaCreacion == tareaNueva.fechaCreacion) {
          tareasPrevias[i] = tareaNueva; // Actualizamos la tarea existente sin perder otras tareas previas
        }
      }
    }

    // 🔹 Guardamos nuevamente la lista completa sin eliminar datos previos
    List<String> tareasJson = tareasPrevias.map((t) => jsonEncode(t.toMap())).toList();
    await prefs.setStringList('tareas', tareasJson);

    debugPrint("Total de tareas guardadas después de la actualización: ${tareasJson.length}");
  }

  Future<void> _cargarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? tareasJson = prefs.getStringList('tareas');

    if (tareasJson != null) {
      setState(() {
        String fechaHoy = DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now());
        //String fechaHoy = DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now().add(Duration(days: -7)));
        _tareas = tareasJson
            .map((tarea) => Tarea.fromMap(jsonDecode(tarea)))
            .where((tarea) => tarea.fechaCreacion == fechaHoy)
            .toList();
      });
    }
  }

  void _mostrarDialogoAgregarTarea() {
  String nombreTarea = '';
  String prioridadTarea = 'Media';
  String fechaTarea = DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now());
  //String fechaTarea = DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now().add(Duration(days: -7)));

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Agregar nueva tarea"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Nombre de la tarea"),
                onChanged: (valor) => nombreTarea = valor,
              ),
              DropdownButton<String>(
                value: prioridadTarea,
                items: ['Alta', 'Media', 'Baja'].map((String prioridad) {
                  return DropdownMenuItem(value: prioridad, child: Text(prioridad));
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    prioridadTarea = valor!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                BuildContext dialogContext = context;

                final prefs = await SharedPreferences.getInstance();
                
                List<String>? tareasJsonPrevias = prefs.getStringList('tareas') ?? [];

                Tarea nuevaTarea = Tarea(
                  nombre: nombreTarea,
                  prioridad: prioridadTarea,
                  fechaCreacion: fechaTarea,
                );

                String nuevaTareaJson = jsonEncode(nuevaTarea.toMap());

                tareasJsonPrevias.add(nuevaTareaJson);

                await prefs.setStringList('tareas', tareasJsonPrevias);

                await _cargarTareas();

                if (mounted) {
                  setState(() {}); 

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                }
              },
              child: const Text("Agregar"),
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('es', null);

    String formattedDate =
        DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now());
    formattedDate = formattedDate[0].toUpperCase() +
        formattedDate.substring(1);

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
                      MaterialPageRoute(builder: (context) => const PomodoroScreen()),
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
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  color: Colors.pink[200],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Mi día",
                            style: TextStyle(color: Colors.pink, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 18, color: Colors.black),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.menu, color: Colors.pink, size: 36),
                        onSelected: (String choice) {
                          if (choice == 'Resumen diario') {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumenDiarioScreen()));
                          } else if (choice == 'Flashcards') {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FlashcardScreen()));
                          } else if (choice == 'Resumen semanal') {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumenSemanalScreen()));
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return ['Resumen diario', 'Flashcards', 'Resumen semanal'].map((String option) {
                            return PopupMenuItem<String>(
                              value: option,
                              child: Text(option, style: const TextStyle(color: Colors.pink)),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text("Tareas",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 1,
                                child: Center(
                                    child: Text("Prioridad",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)))),
                            Expanded(
                                flex: 1,
                                child: Center(
                                    child: Text("Finalizada",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)))),
                            Expanded(
                                flex: 1,
                                child: Center(
                                    child: Text("Eliminar",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)))),
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
                                          Text(_tareas[index].nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(_tareas[index].fechaCreacion, style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
                                              color: _tareas[index].prioridad == "Alta" ? Colors.red
                                              : _tareas[index].prioridad == "Media" ? Colors.orange
                                              : Colors.green,
                                            ),
                                          ),
                                      ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: IconButton(
                                        icon: Icon(
                                          _tareas[index].finalizada ? Icons.check_circle : Icons.cancel,
                                          color: _tareas[index].finalizada ? Colors.green : Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _tareas[index].finalizada = !_tareas[index].finalizada;
                                            _guardarTareas();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _tareas.removeAt(index);
                                            _guardarTareas();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ElevatedButton(
                            onPressed: _mostrarDialogoAgregarTarea,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Agregar tarea...",
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
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
