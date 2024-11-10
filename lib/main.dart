import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const StrikeFour());
}

class StrikeFour extends StatelessWidget {
  const StrikeFour({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Strike 4',
      debugShowCheckedModeBanner: false,
      home: GameBoard(),
    );
  }
}

enum Disc {
  red(color: Colors.red),
  yellow(color: Color(0xFFE5CE03));

  final Color color;

  const Disc({required this.color});
}

enum GameResult { ongoing, yellowWin, redWin, draw }

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  final int rowCount = 6;
  final int columnCount = 7;
  late final int totalDiscs = rowCount * columnCount;
  Map<int, Disc> board = {};
  GameResult currentGameState = GameResult.ongoing;

  Disc activeDisc = Disc.yellow;

  void toggleActiveDisc() {
    if (activeDisc == Disc.yellow) {
      activeDisc = Disc.red;
    } else {
      activeDisc = Disc.yellow;
    }
  }

  void onDiscDrop(int position) {
    // Don't allow moves if game is already over
    if (currentGameState != GameResult.ongoing) return;

    if (board.length == totalDiscs) {
      return;
    }

    final droppedColumn = position % columnCount;
    final possibleColumnPositions = List.generate(
        rowCount, (index) => droppedColumn + (index * columnCount));

    for (var element in possibleColumnPositions) {
      if (!board.containsKey(element)) {
        setState(() {
          board[element] = activeDisc;

          // Check game state after each move
          final (gameResult, winningPositions) = checkGameState();
          debugPrint(winningPositions.toString());
          currentGameState = gameResult; // Update game state

          switch (gameResult) {
            case GameResult.yellowWin:
              Future.delayed(const Duration(milliseconds: 100), () {
                _showGameEndDialog('Yellow wins! 🎉');
              });
              break;
            case GameResult.redWin:
              Future.delayed(const Duration(milliseconds: 100), () {
                _showGameEndDialog('Red wins! 🎉');
              });
              break;
            case GameResult.draw:
              Future.delayed(const Duration(milliseconds: 100), () {
                _showGameEndDialog('Game is a draw! 🤝');
              });
              break;
            case GameResult.ongoing:
              toggleActiveDisc(); // Only toggle if game is still ongoing
              break;
          }
        });
        return;
      }
    }
  }

  void resetGame() {
    setState(() {
      board.clear();
      currentGameState = GameResult.ongoing;
      activeDisc = Disc.yellow;
    });
  }

  void _showGameEndDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
            ),
          ],
        );
      },
    );
  }

  (GameResult, List<int>?) checkGameState() {
    // Check for winner first
    if (board.length >= 7) {
      // Minimum moves needed for a win
      // Check horizontal wins
      for (int row = 0; row < rowCount; row++) {
        for (int col = 0; col <= columnCount - 4; col++) {
          int position = row * columnCount + col;
          if (!board.containsKey(position)) continue;

          bool isWin = true;
          Disc color = board[position]!;
          List<int> winningPositions = [position];

          for (int i = 1; i < 4; i++) {
            int nextPos = position + i;
            if (board[nextPos] != color) {
              isWin = false;
              break;
            }
            winningPositions.add(nextPos);
          }

          if (isWin) {
            return (
              color == Disc.yellow ? GameResult.yellowWin : GameResult.redWin,
              winningPositions
            );
          }
        }
      }

      // Check vertical wins
      for (int row = 0; row <= rowCount - 4; row++) {
        for (int col = 0; col < columnCount; col++) {
          int position = row * columnCount + col;
          if (!board.containsKey(position)) continue;

          bool isWin = true;
          Disc color = board[position]!;
          List<int> winningPositions = [position];

          for (int i = 1; i < 4; i++) {
            int nextPos = position + (i * columnCount);
            if (board[nextPos] != color) {
              isWin = false;
              break;
            }
            winningPositions.add(nextPos);
          }

          if (isWin) {
            return (
              color == Disc.yellow ? GameResult.yellowWin : GameResult.redWin,
              winningPositions
            );
          }
        }
      }

      // Check diagonal wins (bottom-left to top-right)
      for (int row = 3; row < rowCount; row++) {
        for (int col = 0; col <= columnCount - 4; col++) {
          int position = row * columnCount + col;
          if (!board.containsKey(position)) continue;

          bool isWin = true;
          Disc color = board[position]!;
          List<int> winningPositions = [position];

          for (int i = 1; i < 4; i++) {
            int nextPos = position - (i * (columnCount - 1));
            if (board[nextPos] != color) {
              isWin = false;
              break;
            }
            winningPositions.add(nextPos);
          }

          if (isWin) {
            return (
              color == Disc.yellow ? GameResult.yellowWin : GameResult.redWin,
              winningPositions
            );
          }
        }
      }

      // Check diagonal wins (top-left to bottom-right)
      for (int row = 0; row <= rowCount - 4; row++) {
        for (int col = 0; col <= columnCount - 4; col++) {
          int position = row * columnCount + col;
          if (!board.containsKey(position)) continue;

          bool isWin = true;
          Disc color = board[position]!;
          List<int> winningPositions = [position];

          for (int i = 1; i < 4; i++) {
            int nextPos = position + (i * (columnCount + 1));
            if (board[nextPos] != color) {
              isWin = false;
              break;
            }
            winningPositions.add(nextPos);
          }

          if (isWin) {
            return (
              color == Disc.yellow ? GameResult.yellowWin : GameResult.redWin,
              winningPositions
            );
          }
        }
      }
    }

    // Check for draw - if board is full and no winner
    if (board.length == totalDiscs) {
      return (GameResult.draw, null);
    }

    // Game is still ongoing
    return (GameResult.ongoing, null);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate the available height (excluding app bar and status bar)
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final availableHeight = screenSize.height -
        appBarHeight -
        statusBarHeight -
        bottomPadding -
        30; // 30 for AppBar bottom

    // Calculate the available width
    final availableWidth = screenSize.width;

    // Determine cell size based on available space
    final cellSize = min(
        availableWidth / columnCount, // Width constrained
        availableHeight / rowCount // Height constrained
        );

    // Calculate grid dimensions
    final gridWidth = cellSize * columnCount;
    final gridHeight = cellSize * rowCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strike 4'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AlertDialog(
                  content: Text(
                      'It needs two players playing on the opposite side. One player will be playing with red colour coins while the other with yellow colour coins. Whoever gets four coins in a row first is the winner.Players take turns placing checkers into the grid until one player has a row of 4 of his or her checkers in a row. The row can be up and down (vertical), across (horizontal), or diagonal.'),
                ),
              );
            },
            icon: const Icon(Icons.help),
            tooltip: 'How to Play',
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              text: TextSpan(
                text: 'Current Turn: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: activeDisc == Disc.yellow ? "Yellow" : "Red",
                    style: TextStyle(color: activeDisc.color),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: gridWidth,
          height: gridHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              childAspectRatio: 1, // Keep cells square
            ),
            reverse: true,
            itemBuilder: (context, index) {
              Disc? cellState = board[index];
              return InkWell(
                onTap: () => onDiscDrop(index),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color:
                        cellState == null ? Colors.grey[200] : cellState.color,
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(
                        cellSize / 2), // Make cells circular
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: totalDiscs,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF0C31B5),
    );
  }
}
