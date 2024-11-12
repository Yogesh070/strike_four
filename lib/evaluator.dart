import 'dart:math';

import 'package:strike_four/main.dart';

class BoardEvaluator {
  static const int winScore = 1000000;
  static const int score3inROW = 100;
  static const int score2InROW = 10;
  static const int centerControl = 3;

  // Evaluate board state and return probabilities for both players
  static (double yellowProb, double redProb) evaluatePosition(
      Map<int, Disc> board, int rowCount, int columnCount) {
    int yellowScore =
        _evaluateForPlayer(board, Disc.yellow, rowCount, columnCount);
    int redScore = _evaluateForPlayer(board, Disc.red, rowCount, columnCount);

    // Convert scores to probabilities between 0 and 1
    if (yellowScore == winScore) return (1.0, 0.0);
    if (redScore == winScore) return (0.0, 1.0);

    // Calculate total score (avoiding division by zero)
    int totalScore = max(yellowScore.abs() + redScore.abs(), 1);

    // Convert to probabilities
    double yellowProb = (yellowScore + totalScore) / (2 * totalScore);
    double redProb = (redScore + totalScore) / (2 * totalScore);

    // Normalize probabilities to sum to 1
    double sum = yellowProb + redProb;
    return (yellowProb / sum, redProb / sum);
  }

  static int _evaluateForPlayer(
      Map<int, Disc> board, Disc player, int rowCount, int columnCount) {
    int score = 0;

    // Check for immediate win
    if (_checkWin(board, player, rowCount, columnCount)) {
      return winScore;
    }

    // Add score for center control (middle column positions are valuable)
    int centerColumn = columnCount ~/ 2;
    for (int row = 0; row < rowCount; row++) {
      int pos = row * columnCount + centerColumn;
      if (board[pos] == player) {
        score += centerControl;
      }
    }

    // Evaluate horizontal sequences
    score += _evaluateSequences(
        board,
        player,
        rowCount,
        columnCount,
        (row, col) => row * columnCount + col, // horizontal direction
        (pos, i) => pos + i);

    // Evaluate vertical sequences
    score += _evaluateSequences(
        board,
        player,
        rowCount,
        columnCount,
        (row, col) => col * rowCount + row, // vertical direction
        (pos, i) => pos + i * columnCount);

    // Evaluate diagonal sequences (bottom-left to top-right)
    score += _evaluateDiagonals(board, player, rowCount, columnCount, true);

    // Evaluate diagonal sequences (top-left to bottom-right)
    score += _evaluateDiagonals(board, player, rowCount, columnCount, false);

    return score;
  }

  static bool _checkWin(
      Map<int, Disc> board, Disc player, int rowCount, int columnCount) {
    // Check horizontal
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col <= columnCount - 4; col++) {
        bool win = true;
        for (int i = 0; i < 4; i++) {
          if (board[row * columnCount + col + i] != player) {
            win = false;
            break;
          }
        }
        if (win) return true;
      }
    }

    // Check vertical
    for (int row = 0; row <= rowCount - 4; row++) {
      for (int col = 0; col < columnCount; col++) {
        bool win = true;
        for (int i = 0; i < 4; i++) {
          if (board[(row + i) * columnCount + col] != player) {
            win = false;
            break;
          }
        }
        if (win) return true;
      }
    }

    // Check diagonals
    for (int row = 0; row <= rowCount - 4; row++) {
      for (int col = 0; col <= columnCount - 4; col++) {
        // Check diagonal (top-left to bottom-right)
        bool win = true;
        for (int i = 0; i < 4; i++) {
          if (board[(row + i) * columnCount + col + i] != player) {
            win = false;
            break;
          }
        }
        if (win) return true;

        // Check diagonal (bottom-left to top-right)
        if (row >= 3) {
          win = true;
          for (int i = 0; i < 4; i++) {
            if (board[(row - i) * columnCount + col + i] != player) {
              win = false;
              break;
            }
          }
          if (win) return true;
        }
      }
    }

    return false;
  }

  static int _evaluateSequences(
    Map<int, Disc> board,
    Disc player,
    int rowCount,
    int columnCount,
    int Function(int, int) getStartPosition,
    int Function(int, int) getNextPosition,
  ) {
    int score = 0;

    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < columnCount - 3; col++) {
        int startPos = getStartPosition(row, col);
        int consecutive = 0;
        int empty = 0;

        for (int i = 0; i < 4; i++) {
          int pos = getNextPosition(startPos, i);
          if (board[pos] == player) {
            consecutive++;
          } else if (!board.containsKey(pos)) {
            empty++;
          }
        }

        // Score based on number of consecutive pieces and empty spaces
        if (empty > 0 && consecutive > 0) {
          if (consecutive == 3) score += score3inROW;
          if (consecutive == 2) score += score2InROW;
        }
      }
    }

    return score;
  }

  static int _evaluateDiagonals(Map<int, Disc> board, Disc player, int rowCount,
      int columnCount, bool ascending) {
    int score = 0;

    for (int row = ascending ? 3 : 0;
        ascending ? row < rowCount : row <= rowCount - 4;
        row++) {
      for (int col = 0; col <= columnCount - 4; col++) {
        int consecutive = 0;
        int empty = 0;

        for (int i = 0; i < 4; i++) {
          int currentRow = ascending ? row - i : row + i;
          int pos = currentRow * columnCount + col + i;

          if (board[pos] == player) {
            consecutive++;
          } else if (!board.containsKey(pos)) {
            empty++;
          }
        }

        // Score based on number of consecutive pieces and empty spaces
        if (empty > 0 && consecutive > 0) {
          if (consecutive == 3) score += score3inROW;
          if (consecutive == 2) score += score2InROW;
        }
      }
    }

    return score;
  }
}
