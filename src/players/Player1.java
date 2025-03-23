package players;
import game.*;

import java.util.List;

public class Player1 extends Player {

    public Player1(Board board) {
        super(board);
    }

    @Override
    public Move nextMove() {
        List<Move> possibleMoves = board.getPossibleMoves();
        if (possibleMoves.isEmpty()) return null;

        // Simple strategy: Always pick the first available direction
        return possibleMoves.get(0);
    }
}
