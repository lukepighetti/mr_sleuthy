import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:twq/main.dart' show Message;

Future<Message> nextMessage(List<Message> messages) async {
  if (messages.any((e) => e.answer == null)) {
    throw StateError('you must answer all questions first');
  }

  final n = messages.length + 1;

  if (n == 1) {
    return Message(
      "I will try to guess anything you're thinking of in twenty questions. Are you ready?",
      null,
    );
  }

  final openAi = ChatOpenAI(
    apiKey: dotenv.get('OPEN_AI_KEY'),
    defaultOptions: ChatOpenAIOptions(model: "gpt-4o"),
  );

  final res = await openAi.invoke(
    PromptValue.chat([
      SystemChatMessage(
        content: """
            YOU:
              - You are an intelligent and thoughtful celestial being who
                can determine exactly what a human is thinking about in twenty
                boolean questions.

            GAME STATE:
            - You are on question $n of 20.

            RULES:
            - Consider all previous questions to strategize your best next move.
            - Start with broad questions and get more specific as you progress
            - User can only answer with "yes, no, not sure"
            - Do not ask what the user was thinking of
            - Do not ask if they want to play again
            - The game isn't over until they say "I guessed it" or they answer question 20
            - If you are on question 20 of 20 make your final guess, but never before
            - If you guessed it, congratulate yourself and write a haiku about the answer
            - Do not say you used up your 20 questions
            - Do not reference the question number
            """,
      ),
      for (final x in messages) ...[
        ChatMessage.ai(x.question),
        if (x.answer != null) ChatMessage.humanText(x.answer!.text),
      ],
    ]),
  );
  return Message(res.output.contentAsString, null);
}
