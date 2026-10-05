import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'resumen_diario_screen.dart';
import 'main.dart';
import 'resumen_semanal_screen.dart';

class FlashcardTema {
  String nombre;
  List<Map<String, String>> tarjetas;

  FlashcardTema({required this.nombre, List<Map<String, String>>? tarjetas})
      : tarjetas = tarjetas ?? [];

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'tarjetas': tarjetas,
    };
  }

  factory FlashcardTema.fromMap(Map<String, dynamic> map) {
    return FlashcardTema(
      nombre: map['nombre'],
      tarjetas: List<Map<String, String>>.from(
          map['tarjetas']?.map((e) => Map<String, String>.from(e)) ?? []),
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  FlashcardScreenState createState() => FlashcardScreenState();
}

class FlashcardScreenState extends State<FlashcardScreen> {
  List<FlashcardTema> _temas = [];

  @override
  void initState() {
    super.initState();
    _cargarTemas();
  }

  void _guardarTemas() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> temasJson =
        _temas.map((tema) => jsonEncode(tema.toMap())).toList();
    await prefs.setStringList('flashcard_temas', temasJson);
  }

  void _cargarTemas() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? temasJson = prefs.getStringList('flashcard_temas');

    if (temasJson != null) {
      setState(() {
        _temas = temasJson
            .map((tema) => FlashcardTema.fromMap(jsonDecode(tema)))
            .toList();
      });
    }
  }

  void _mostrarDialogoAgregarTema() {
    String nombreTema = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Agregar nuevo tema"),
            content: TextField(
              decoration: const InputDecoration(labelText: "Nombre del tema"),
              onChanged: (valor) => nombreTema = valor,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () {
                  if (nombreTema.isNotEmpty) {
                    setState(() {
                      _temas.add(FlashcardTema(nombre: nombreTema));
                      _guardarTemas();
                    });
                    Navigator.pop(context);
                    _cargarTemas();
                  }
                },
                child: const Text("Aceptar"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoAgregarFlashcard(int index) {
    String pregunta = '';
    String respuesta = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Agregar Flashcard"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Pregunta"),
                  onChanged: (valor) => pregunta = valor,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: "Respuesta"),
                  onChanged: (valor) => respuesta = valor,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (pregunta.isNotEmpty && respuesta.isNotEmpty) {
                    setState(() {
                      _temas[index].tarjetas.add({'pregunta': pregunta, 'respuesta': respuesta});
                      _guardarTemas();
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Aceptar"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoEstudiarFlashcards(int index) {
    int preguntaActual = 0;
    bool mostrarRespuesta = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (_temas[index].tarjetas.isEmpty) {
              return AlertDialog(
                title: const Text("No hay preguntas"),
                content: const Text("Agrega preguntas para empezar a estudiar."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Aceptar"),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text("Estudiar Flashcards"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _temas[index].tarjetas[preguntaActual]['pregunta']!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (mostrarRespuesta)
                    Text(
                      _temas[index].tarjetas[preguntaActual]['respuesta']!,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() {
                    mostrarRespuesta = true;
                  }),
                  child: const Text("Mostrar respuesta"),
                ),
                if (preguntaActual < _temas[index].tarjetas.length - 1)
                  TextButton(
                    onPressed: () => setState(() {
                      mostrarRespuesta = false;
                      preguntaActual++;
                    }),
                    child: const Text("Siguiente pregunta"),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('es', null);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 80,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
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
                      const Text(
                        "Flashcards",
                        style: TextStyle(
                            color: Colors.pink,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.menu, color: Colors.pink, size: 36),
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
                                    builder: (context) => const FlashcardScreen()));
                          } else if (choice == 'Resumen semanal') {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumenSemanalScreen()));
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
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _temas.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_temas[index].nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _mostrarDialogoAgregarFlashcard(index),
                                            child: const Text("Agregar"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => _mostrarDialogoEstudiarFlashcards(index),
                                            child: const Text("Estudiar"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _temas.removeAt(index);
                                                _guardarTemas();
                                              });
                                            },
                                            child: const Text("Eliminar"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ElevatedButton(
                            onPressed: _mostrarDialogoAgregarTema,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Agregar nueva", style: TextStyle(fontSize: 18)),
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
