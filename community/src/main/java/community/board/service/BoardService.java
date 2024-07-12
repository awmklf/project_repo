package community.board.service;

import java.util.List;

public interface BoardService {

	/** 게시글 목록 조회 */
	public List<BoardVO> selectBoardList(BoardVO vo) throws Exception;

	/** 게시글 수 조회 */
	public int selectBoardListCnt(BoardVO vo) throws Exception;

	/** 게시글 내용 조회 */
	public BoardVO selectBoard(BoardVO vo) throws Exception;

	/** 게시글 작성 */
	public String insertBoard(BoardVO vo) throws Exception;
}
