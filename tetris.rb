# encoding: utf-8
# ウィンドウのサンプル

require 'curses'

Curses.init_screen
Curses.noecho

W = 10
H = 20
BLANK = 0
FILL = 1

$stage = Array.new(H){Array.new(W){BLANK}}
$top = 0
$left = W/2-1
# $block = [
# 	[1,1,1],
# 	[0,0,1],
# 	[0,0,0]
# ]

$block = [
	[1],
	[1],
	[1],
	[1]
]

p $stage

# ブロックをおいたステージを返す
def put_block_stage
	field = $stage.map(&:clone)
	$block.each_with_index{|l, i|
		l.each_with_index{|c, j|
			field[i+$top][j+$left] = c if c == 1
		}
	}
	field

end

# ブロックをステージに設置して描画
def display win, stage=put_block_stage
	H.times{|i|
		win.setpos(i+1, 1)
		line = stage[i].map{|cell| ['  ', "圖"][cell]}.join
	    win.addstr(line)
	}
	win.refresh
end

# 新しい場所にブロックがいけるか
def valid? add_top, add_left
	top = $top + add_top
	left = $left + add_left

	if top == H || left == -1 || left == W
		false
	else
		$block.each_with_index{|l, i|
			l.each_with_index{|c, j|
				new_i = i + top
				new_j = j + left
				# ステージから出てしまうときはfalse
				return false if c == 1 && (new_i == H || new_j == -1 || new_j == W)
				# 既存のブロックとぶつかるときもfalse
				return false if c == 1 && ($stage[new_i][new_j] == 1)
			}
		}
		true
	end
end

# ブロックの操作もしつつ待つ
def type_wait win, wait, rate=100
	rate.times{
    	c = win.getch
    	case c
    	when 'a'
    		$left -= 1 if valid?(0, -1)
    		display(win)
    	when 's'
    		$left += 1 if valid?(0, 1)
    		display(win)
    	when 'z'
    		$top += 1 if valid?(1, 0)
    		display(win)
    	end
    	sleep wait.to_f / rate
    }
end

# ブロックが消せたら消す
def remove_block win
	# 削除する行のindexをあつめる
	remove_lines = (H-1).downto(0).select{|i|
		# そろっていたらtrue
		$stage[i].all?{|e| e==1}
	}
	
	# 削除する行があるなら
	if !remove_lines.empty?
		# 削除するまえ
		pre_stage = $stage.map(&:clone)
		# 削除後（穴抜き）
		post_stage = $stage.map.with_index{|l, i|
			remove_lines.include?(i) ? Array.new(W, 0): l
		}

		# 削除する行を点滅させる
		3.times{
			display(win, pre_stage)
			sleep 0.1
			display(win, post_stage)
			sleep 0.1
		}

		# 削除する
		idx = H-1
		while idx >= 0
			if $stage[idx].all?{|e| e==1}
				# 詰める
				idx.downto(1){|j|
					$stage[j] = $stage[j-1]
				}
			else
				idx -= 1
			end
		end
	end


end

begin
    # s = "Hello World!"
    win = Curses::Window.new(H+2, (W+1)*2, 1, 2)
    win.box(?|,'-',?+)
    win.nodelay = 1

    loop{
    	# 画面表示
	    display(win)

	    # 落下できるなら
	    if valid?(1, 0)
	    	# 落下する
		    $top += 1
		    # 落下時間まちながらタイプもできる
			type_wait(win, 0.5)
		else
			# 接着待ち
			type_wait(win, 0.5)
			# 接着する
			$stage = put_block_stage
			# ブロックをけす
			remove_block(win)
			# 次のブロック作成
			$top = 0
			$left = W/2 - 1
		end	   	
	    
	}

	win.nodelay = 0
    win.getch
    win.close
ensure
    Curses.close_screen
end