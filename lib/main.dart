import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infamous_squircle/infamous_squircle.dart';
import 'package:twq/next_message.dart';
import 'package:twq/tappable.dart';

void main() async {
  await dotenv.load(fileName: 'assets/.env');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var loading = false;
  final messages = <Message>[];

  bool get guessed => messages.any((e) => e.answer == Answer.guessed);

  @override
  void initState() {
    super.initState();
    handleStartGame();
  }

  void handleStartGame() async {
    next();
  }

  void next() async {
    setState(() => loading = true);
    try {
      final x = await nextMessage(messages);
      setState(() => messages.add(x));
    } catch (e) {
      if (kDebugMode) print(e);
      rethrow;
    }
    setState(() => loading = false);
  }

  void handleTapAnswer(Answer x) {
    setState(() => messages.last.answer = x);
    next();
  }

  void handleRestartGame() {
    setState(() => messages.clear());
    next();
  }

  void handleUndo() {
    setState(() {
      messages.removeLast();
      messages.last.answer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = messages.length;

    // https://x.com/luke_pighetti/status/1916574417540329794
    final actionState = switch (n) {
      1 => ActionState.ready,
      >= 20 || _ when guessed => ActionState.complete,
      _ => ActionState.answering,
    };

    return MaterialApp(
      title: 'Mr Sleuthy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.purple,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 128,
          forceMaterialTransparency: true,
          title: Column(
            spacing: 4,
            children: [
              Circle(diameter: 96, child: Image.asset("assets/icon.jpg")),
              Text(
                "Mr Sleuthy",
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: IconButton.filledTonal(
                onPressed: switch (actionState) {
                  ActionState.ready => null,
                  ActionState.answering => handleUndo,
                  ActionState.complete => handleRestartGame,
                },
                icon: Icon(switch (actionState) {
                  ActionState.ready ||
                  ActionState.answering => Icons.undo_rounded,
                  ActionState.complete => Icons.restart_alt_rounded,
                }),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(8),
          reverse: true,
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, x) in messages.indexed) ...[
                Container(
                  constraints: BoxConstraints(minHeight: 48),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.only(right: 64),
                  decoration: BoxDecoration(
                    color: Style.toColor,
                    borderRadius: Style.questionRadius,
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          x.question,
                          style: GoogleFonts.outfit(fontSize: 16),
                        ),
                      ),
                      Text(
                        "${i + 1}/20",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Style.questionNumberColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (x.answer != null)
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: x.answer?.gradient,
                      borderRadius: Style.answerRadius,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      x.answer!.emoji,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 208, // hand tailored
            margin: EdgeInsets.all(8),
            child: switch (actionState) {
              ActionState.ready => AnswerButton(
                onTap: loading ? null : () => handleTapAnswer(Answer.ready),
                answer: Answer.ready,
              ),
              ActionState.complete => AnswerButton(
                onTap: handleRestartGame,
                answer: Answer.playAgain,
              ),
              ActionState.answering => Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Visibility.maintain(
                    visible: n > 1,
                    child: AnswerButton(
                      answer: Answer.guessed,
                      dense: true,
                      onTap:
                          loading || n == 1
                              ? null
                              : () => handleTapAnswer(Answer.guessed),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final x in [Answer.yes, if (n > 1) Answer.no])
                          Expanded(
                            child: AnswerButton(
                              answer: x,
                              onTap: loading ? null : () => handleTapAnswer(x),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Visibility.maintain(
                    visible: n > 1,
                    child: AnswerButton(
                      answer: Answer.notSure,
                      dense: true,
                      onTap:
                          loading || n == 1
                              ? null
                              : () => handleTapAnswer(Answer.notSure),
                    ),
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

class Style {
  static final toColor = Color(0xFF30212E);

  static final questionRadius = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
    bottomLeft: Radius.circular(0),
    bottomRight: Radius.circular(24),
  );

  static final answerRadius = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
    bottomLeft: Radius.circular(24),
    bottomRight: Radius.circular(0),
  );

  static final questionNumberColor = Color(0xFF6D576A);
}

class Message {
  final String question;
  Answer? answer;

  Message(this.question, this.answer);
}

enum ActionState { ready, answering, complete }

enum Answer {
  ready(
    LinearGradient(
      colors: [
        Color.fromARGB(255, 3, 140, 194),
        Color.fromARGB(255, 2, 108, 189),
      ],
    ),
    "👆",
    "I'm ready!",
  ),
  guessed(
    LinearGradient(
      colors: [
        Color.fromARGB(255, 194, 3, 175),
        Color.fromARGB(255, 189, 2, 158),
      ],
    ),
    "😱",
    "You guessed it!",
  ),
  yes(
    LinearGradient(colors: [Color(0xFF03C27C), Color(0xFF02BD60)]),
    "👍",
    "Yes",
  ),
  no(
    LinearGradient(colors: [Color(0xFFFF6C23), Color(0xFFDB4900)]),
    "👎",
    "No",
  ),
  playAgain(
    LinearGradient(
      colors: [
        Color.fromARGB(255, 142, 36, 170),
        Color.fromARGB(255, 114, 17, 141),
      ],
    ),
    "🔄",
    "Play again",
  ),
  notSure(
    LinearGradient(
      colors: [
        Color.fromARGB(255, 54, 99, 248),
        Color.fromARGB(255, 133, 32, 210),
      ],
    ),
    "🤷‍♂️",
    "Not sure",
  );

  final LinearGradient gradient;
  final String emoji;
  final String text;

  const Answer(this.gradient, this.emoji, this.text);
}

class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.answer,
    required this.onTap,
    this.dense = false,
  });

  final Answer answer;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Rectangle(
        radius: 24,
        height: 48,
        gradient: answer.gradient,
        alignment: Alignment.center,
        child: Text(
          "${answer.emoji} ${answer.text}",
          style: GoogleFonts.fredoka(
            fontSize: dense ? 24 : 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
