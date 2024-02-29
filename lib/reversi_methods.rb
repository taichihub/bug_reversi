# frozen_string_literal: true

require_relative './position'

module ReversiMethods
  WHITE_STONE = 'W'
  BLACK_STONE = 'B'
  BLANK_CELL = '-'

  def build_initial_board
    # boardは盤面を示す二次元配列
    board = Array.new(8) { Array.new(8, BLANK_CELL) }
    board[3][3] = WHITE_STONE # d4
    board[4][4] = WHITE_STONE # e5
    board[3][4] = BLACK_STONE # d5
    board[4][3] = BLACK_STONE # e4
    board
  end

  def output(board)
    puts "  #{Position::COL.join(' ')}"
    board.each_with_index do |row, i|
      print Position::ROW[i]
      row.each do |cell|
        case cell
        when WHITE_STONE then print ' ●'
        when BLACK_STONE then print ' ○'
        else print ' -'
        end
      end
      print "\n"
    end
  end

  def copy_board(to_board, from_board)
    from_board.each_with_index do |cols, row|
      cols.each_with_index do |cell, col|
        to_board[row][col] = cell
      end
    end
  end

  def put_stone(board, cell_ref, stone_color, dry_run: false)
    pos = Position.new(cell_ref)
    
    if pos.invalid?
      raise '無効なポジションです' unless dry_run
      return false
    end
  
    if pos.stone_color(board) != BLANK_CELL
      raise 'すでに石が置かれています' unless dry_run
      return false
    end
  
    copied_board = Marshal.load(Marshal.dump(board))
    copied_board[pos.row][pos.col] = stone_color

    turn_succeed = false
    Position::DIRECTIONS.each do |direction|
      next_pos = pos.next_position(direction)
      if turn(copied_board, next_pos, stone_color, direction)
        turn_succeed = true
      end
    end

    copy_board(board, copied_board) if !dry_run && turn_succeed
    turn_succeed
  end
  
  def turn(board, target_pos, attack_stone_color, direction)
    stones_to_flip = []
    loop do
      return false if target_pos.out_of_board? || target_pos.stone_color(board) == BLANK_CELL
      break if target_pos.stone_color(board) == attack_stone_color
      stones_to_flip << target_pos
      target_pos = target_pos.next_position(direction)
    end

    if stones_to_flip.empty?
      false
    else
      stones_to_flip.each do |pos|
        board[pos.row][pos.col] = attack_stone_color
      end
      true
    end
  end

  def finished?(board)
    !placeable?(board, WHITE_STONE) && !placeable?(board, BLACK_STONE)
  end

  def placeable?(board, stone_color)
    board.flatten.each_index.any? do |i|
      row, col = i / board.size, i % board.size
      next if board[row][col] != BLANK_CELL
      cell_ref = Position.new(row, col).to_cell_ref
      put_stone(board, cell_ref, stone_color, dry_run: true)
    end
  end

  def count_stone(board, stone_color)
    board.flatten.count { |cell| cell == stone_color }
  end
end
