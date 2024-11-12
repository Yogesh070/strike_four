import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strike_four/evaluator.dart';

void main() {
  runApp(const StrikeFour());
}

class StrikeFour extends StatelessWidget {
  const StrikeFour({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Strike Four',
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

  int? hoveredColumn; // Track which column is being hovered
  double? previewYellowProb; // Preview probabilities
  double? previewRedProb;

  Disc activeDisc = Disc.yellow;

  double yellowProbability = 0.5;
  double redProbability = 0.5;

  ValueNotifier<bool> enableProbabilityIndicator = ValueNotifier(false);

  // Get the next available position in a column
  int? getNextAvailablePosition(int column) {
    for (int row = 0; row < rowCount; row++) {
      int position = row * columnCount + column;
      if (!board.containsKey(position)) {
        return position;
      }
    }
    return null; // Column is full
  }

  // Preview the move and calculate probabilities
  void previewMove(int column) {
    if (currentGameState != GameResult.ongoing) return;

    int? position = getNextAvailablePosition(column);
    if (position == null) {
      setState(() {
        hoveredColumn = null;
        previewYellowProb = null;
        previewRedProb = null;
      });
      return;
    }

    // Create a temporary board with the previewed move
    Map<int, Disc> previewBoard = Map.from(board);
    previewBoard[position] = activeDisc;

    // Calculate probabilities for the preview
    final (yellowProb, redProb) =
        BoardEvaluator.evaluatePosition(previewBoard, rowCount, columnCount);

    setState(() {
      hoveredColumn = column;
      previewYellowProb = yellowProb;
      previewRedProb = redProb;
    });
  }

  Widget _buildProbabilityIndicator({bool isPreview = false}) {
    double yellowProb = isPreview ? (previewYellowProb ?? 0.5) : 0.5;
    double redProb = isPreview ? (previewRedProb ?? 0.5) : 0.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Yellow: ${(yellowProb * 100).toStringAsFixed(1)}%'),
              Text('Red: ${(redProb * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  Expanded(
                    flex: (yellowProb * 100).round(),
                    child: Container(
                      color: Colors.yellow.shade600,
                      child: isPreview
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.transparent
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    flex: (redProb * 100).round(),
                    child: Container(
                      color: Colors.red,
                      child: isPreview
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.transparent
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateGameStatus() {
    final (yProb, rProb) =
        BoardEvaluator.evaluatePosition(board, rowCount, columnCount);

    setState(() {
      yellowProbability = yProb;
      redProbability = rProb;
    });
  }

  void toggleActiveDisc() {
    if (activeDisc == Disc.yellow) {
      activeDisc = Disc.red;
    } else {
      activeDisc = Disc.yellow;
    }
  }

  void onDiscDrop(int position) {
    HapticFeedback.selectionClick();
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
          _updateGameStatus();

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
        121;

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
        title: const Text(
          'Strike Four',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to play'),
                  content: SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.5,
                    child: const Text(
                      'It needs two players playing on the opposite side. One player will be playing with red colour coins while the other with yellow colour coins. Whoever gets four coins in a row first is the winner.Players take turns placing checkers into the grid until one player has a row of 4 of his or her checkers in a row. The row can be up and down (vertical), across (horizontal), or diagonal.',
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.help),
            tooltip: 'How to Play',
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Settings'),
                  content: ValueListenableBuilder<bool>(
                    valueListenable: enableProbabilityIndicator,
                    builder: (context, value, child) {
                      return ListTile(
                        title: const Text('Enable Probability Indicator'),
                        leading: CupertinoSwitch(
                          value: value,
                          onChanged: (val) {
                            enableProbabilityIndicator.value = val;
                          },
                        ),
                        subtitle: const Text(
                          'Hover over a column to preview the probability of winning before making a move.',
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          )
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                text: 'Current Turn: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
                children: [
                  TextSpan(
                    text: activeDisc == Disc.yellow ? "Yellow" : "Red",
                    style: TextStyle(color: activeDisc.color),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            ValueListenableBuilder(
                valueListenable: enableProbabilityIndicator,
                builder: (context, value, child) {
                  return Visibility(
                    visible: value,
                    child: Column(
                      children: [
                        _buildProbabilityIndicator(isPreview: true),
                        const SizedBox(
                          height: 8,
                        ),
                        SizedBox(
                          width: gridWidth,
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(columnCount, (column) {
                              bool isHovered = hoveredColumn == column;
                              return Tooltip(
                                message:
                                    'Preview for column ${(hoveredColumn ?? 0) + 1}',
                                child: MouseRegion(
                                  onEnter: (_) => previewMove(column),
                                  onExit: (_) => setState(() {
                                    hoveredColumn = null;
                                    previewYellowProb = null;
                                    previewRedProb = null;
                                  }),
                                  child: Container(
                                    width: cellSize,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? Colors.black12
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      color: isHovered
                                          ? activeDisc.color
                                          : Colors.transparent,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            SizedBox(
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
                        color: cellState == null
                            ? Colors.grey[200]
                            : cellState.color,
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
          ],
        ),
      ),
    );
  }
}
