import 'dart:async'; // Importa herramientas para manejar temporizadores y tareas asincrónicas.
import 'package:flutter/material.dart'; // Importa el framework Flutter para construir UI.
import 'package:pomo_time/resumen_semanal_screen.dart'; // Importa la pantalla de resumen semanal.
import 'resumen_diario_screen.dart'; // Importa la pantalla de resumen diario.
import 'flashcard_screen.dart'; // Importa la pantalla de flashcards.

void main() {
  runApp(const PomoTimeApp()); // Inicia la aplicación llamando a la clase principal.
}

class PomoTimeApp extends StatelessWidget { // Define la clase principal de la app.
  const PomoTimeApp({super.key}); // Constructor de la app.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Oculta la bandera de debug en la esquina superior derecha.
      theme: ThemeData(
        primarySwatch: Colors.pink, // Define el color primario de la app.
      ),
      home: const PomodoroScreen(), // Establece la pantalla inicial como PomodoroScreen.
    );
  }
}

class PomodoroScreen extends StatefulWidget { // Define un widget con estado para la pantalla principal.
  const PomodoroScreen({super.key});

  @override
  PomodoroScreenState createState() => PomodoroScreenState(); // Crea el estado asociado a la pantalla.
}

class PomodoroScreenState extends State<PomodoroScreen> {
  int _minutes = 25; // Minutos restantes en el temporizador.
  int _seconds = 0; // Segundos restantes en el temporizador.
  bool _isRunning = false; // Indica si el temporizador está activo.
  Timer? _timer; // Variable para manejar el temporizador.

  // Inicia el temporizador y actualiza la interfaz cada segundo.
  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Si el temporizador llega a cero, se detiene y muestra un mensaje.
        if (_minutes == 0 && _seconds == 0) {
          _timer?.cancel();
          _isRunning = false;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("¡Felicidades!"),
              content: const Text("Terminaste tu pomodoro, sigue así.\nSi terminste tu tarea no olvides marcarla como finalizada."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetTimer();
                  },
                  child: const Text("Aceptar"),
                ),
              ],
            ),
          );
        } else {
          // Actualiza los segundos y minutos.
          if (_seconds > 0) {
            _seconds--;
          } else if (_minutes > 0) {
            _minutes--;
            _seconds = 59;
          }
        }
      });
    });
  }

  // Restablece el temporizador a su estado inicial.
  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _minutes = 25;
      _seconds = 0;
      _isRunning = false;
    });
  }

  // Incrementa el tiempo del temporizador si no está corriendo.
  void _incrementTime() {
    if (!_isRunning) {
      setState(() {
        _minutes++;
      });
    }
  }

  // Disminuye el tiempo del temporizador si no está corriendo.
  void _decrementTime() {
    if (!_isRunning && _minutes > 1) {
      setState(() {
        _minutes--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[200],
      body: Column(
        children: [
          // Barra superior con el título y menú de opciones.
          AppBar(
            title: const Text(
              "PomoTime",
              style: TextStyle(
                color: Colors.pink,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.pink[200],
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu, color: Colors.pink, size: 36),
                onSelected: (String choice) {
                  // Navegación a otras pantallas desde el menú.
                  if (choice == 'Resumen diario') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResumenDiarioScreen(),
                      ),
                    );
                  } else if (choice == 'Flashcards') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FlashcardScreen(),
                      ),
                    );
                  } else if (choice == 'Resumen semanal') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResumenSemanalScreen(),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return ['Resumen diario', 'Flashcards', 'Resumen semanal']
                      .map((String option) {
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
          // Línea decorativa debajo del título.
          Container(
            height: 3,
            width: MediaQuery.of(context).size.width * 0.75,
            color: Colors.pink,
            alignment: Alignment.center,
          ),
          // Contenedor principal del temporizador.
          Expanded(
            child: Center(
              child: Container(
                width: 400,
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Muestra el tiempo y botones para ajustar los minutos.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _isRunning
                          ? [
                              Text(
                                '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ]
                          : [
                              IconButton(
                                icon: const Icon(Icons.remove,
                                    size: 40, color: Colors.white),
                                onPressed: _decrementTime,
                              ),
                              const SizedBox(width: 20),
                              Text(
                                '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                icon: const Icon(Icons.add,
                                    size: 40, color: Colors.white),
                                onPressed: _incrementTime,
                              ),
                            ],
                    ),
                    const SizedBox(height: 20),
                    // Botones para iniciar y resetear el temporizador.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: !_isRunning
                          ? [
                              ElevatedButton(
                                onPressed: _startTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.pink,
                                ),
                                child: const Text("Comenzar",
                                    style: TextStyle(fontSize: 18)),
                              ),
                              ElevatedButton(
                                onPressed: _resetTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.pink,
                                ),
                                child: const Text("Reestablecer",
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ]
                          : [
                              ElevatedButton(
                                onPressed: _resetTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.pink,
                                ),
                                child: const Text("Reestablecer",
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}