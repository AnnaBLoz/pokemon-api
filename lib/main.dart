import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(PokemonQuizApp());
}

class PokemonQuizApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokemon Quiz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PokemonQuizScreen(),
    );
  }
}

class Pokemon {
  final String name;
  final String imageUrl;

  Pokemon({required this.name, required this.imageUrl});
}

class PokemonQuizScreen extends StatefulWidget {
  @override
  _PokemonQuizScreenState createState() => _PokemonQuizScreenState();
}

class _PokemonQuizScreenState extends State<PokemonQuizScreen> {
  final List<String> pokemonList = [];
  final List<Pokemon> pokemonHistory = [];
  int correctAnswers = 0;
  int currentRound = 0;
  late Pokemon currentPokemon;
  List<String> answerOptions = [];
  bool isLoading = true; // Variável de estado para controlar o carregamento

  @override
  void initState() {
    super.initState();

    fetchPokemonList();
  }

  Future<void> fetchPokemonList() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=150'));
    final pokemonData = json.decode(response.body)['results'] as List<dynamic>;

    setState(() {
      pokemonList.addAll(pokemonData.map((pokemon) => pokemon['name'].toString()));
      isLoading = false; // Altera o estado de carregamento para falso quando a busca estiver completa.
    });

    startGame();
  }

  void startGame() {
    if (isLoading) {
      return;
    }

    if (currentRound == 10) {
      endGame();
      return;
    }

    currentPokemon = getRandomPokemon();
    answerOptions = generateRandomPokemonNames();

    setState(() {
      currentRound++;
    });
  }

  Pokemon getRandomPokemon() {
    final randomIndex = Random().nextInt(pokemonList.length);
    final pokemonName = pokemonList[randomIndex];
    final pokemonImageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${randomIndex + 1}.png';

    return Pokemon(name: pokemonName, imageUrl: pokemonImageUrl);
  }

  List<String> generateRandomPokemonNames() {
    final random = Random();
    final pokemonNames = <String>[];

    // Add the correct Pokémon name
    pokemonNames.add(currentPokemon.name);

    while (pokemonNames.length < 4) {
      final randomIndex = random.nextInt(pokemonList.length);
      final pokemonName = pokemonList[randomIndex];
      if (!pokemonNames.contains(pokemonName)) {
        pokemonNames.add(pokemonName);
      }
    }

    pokemonNames.shuffle(random);

    return pokemonNames;
  }

  void checkAnswer(String selectedAnswer, String correctAnswer) {
    if (selectedAnswer == correctAnswer) {
      setState(() {
        correctAnswers++;
      });
    }

    pokemonHistory.add(currentPokemon);

    startGame();
  }

  void endGame() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fim do Jogo'),
          content: Text('Total de acertos: $correctAnswers'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  correctAnswers = 0;
                  currentRound = 0;
                  pokemonHistory.clear();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Reiniciar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz de Pokémon'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Tela de carregamento
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.network(currentPokemon.imageUrl),
                ),
                for (final option in answerOptions)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () => checkAnswer(option, currentPokemon.name),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red,
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
