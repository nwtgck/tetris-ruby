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
$left = 0

# ブロックが1マス落下する時間
DROP_TIME = 1.0
# ブロックが接着される時間
PUT_TIME = 0.5

BLOCKS = [
	# I
	[
		[0,0,0,0,0],
		[0,0,0,0,0],
		[0,1,1,1,1],
		[0,0,0,0,0],
		[0,0,0,0,0],
	],

	# L
	[
		[0,0,0,0,0],
		[0,0,0,1,0],
		[0,1,1,1,0],
		[0,0,0,0,0],
		[0,0,0,0,0],
	],

	# 逆L
	[
		[0,0,0,0,0],
		[0,1,0,0,0],
		[0,1,1,1,0],
		[0,0,0,0,0],
		[0,0,0,0,0],
	],

	# Z
	[
		[0,0,0,0,0],
		[0,1,1,0,0],
		[0,0,1,1,0],
		[0,0,0,0,0],
		[0,0,0,0,0],
	],

	#  逆Z
	[
		[0,0,0,0,0],
		[0,0,1,1,0],
		[0,1,1,0,0],
		[0,0,0,0,0],
		[0,0,0,0,0],
	],

	# T
	[
		[0,0,0,0,0],
		[0,0,1,0,0],
		[0,1,1,1,0],
		[0,0,0,0,0],
		[0,0,0,0,0],
	],

	# O
	[
		[0,0,0,0],
		[0,1,1,0],
		[0,1,1,0],
		[0,0,0,0]
	]

]


# ブロックの初期設定
def init_block
	$block = BLOCKS.sample
	$top = -1
	$left = W/2 - ($block.first.size==5 ? 3 : 2);
end



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
		begin
			line = stage[i].map{|cell| ['  ', "回"][cell]}.join
		rescue
			p [i, $!]
			# throw $!
		end
	    win.addstr(line)
	}
	win.refresh
end

# 新しい場所にブロックがいけるか
def valid? add_top, add_left, block=$block
	top = $top + add_top
	left = $left + add_left

	block.each_with_index{|l, i|
		l.each_with_index{|c, j|
			new_i = i + top
			new_j = j + left
			# ステージから出てしまうときはfalse
			return false if c == 1 && (new_i >= H || new_j <= -1 || new_j >= W)
			# 既存のブロックとぶつかるときもfalsensn
			return false if c == 1 && ($stage[new_i][new_j] == 1)
		}
	}
	true
	
end

# 左回転
def lrotate block=$block
	block[0].reverse.zip(*block[1..-1].map(&:reverse))
end

# 右回転
def rrotate block=$block
	lrotate(lrotate(lrotate(block)))
end

# ブロックの操作もしつつ待つ
def type_wait win, wait, rate=1000
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
    	when 'n'
    		block = lrotate
    		if valid?(0, 0, block)
    			$block = block
    		elsif valid?(0, 1, block)
    			$block = block
    			$left += 1
    		elsif valid?(0, 2, block)
    			$block = block
    			$left += 2
    		elsif valid?(0, 3, block)
    			$block = block
    			$left += 3
    		elsif valid?(0, -1, block)
    			$block = block
    			$left += -1
    		elsif valid?(0, -2, block)
    			$block = block
    			$left += -2
    		elsif valid?(0, -3, block)
    			$block = block
    			$left += -3
    		end
    			
    		display(win)
    	when 'm'
    		block = rrotate
    		if valid?(0, 0, block)
    			$block = block
    		elsif valid?(0, 1, block)
    			$block = block
    			$left += 1
    		elsif valid?(0, 2, block)
    			$block = block
    			$left += 2
    		elsif valid?(0, 3, block)
    			$block = block
    			$left += 3
    		elsif valid?(0, -1, block)
    			$block = block
    			$left += -1
    		elsif valid?(0, -2, block)
    			$block = block
    			$left += -2
    		elsif valid?(0, -3, block)
    			$block = block
    			$left += -3
    		end
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
		# 削除アニメーション1
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


		# 削除アニメーション2
		# (0..W).each{|w|
		# 	remove_lines.each{|idx|
		# 		win.setpos(idx+1, 1)
		# 		win.addstr('圖'*(W-w) + '　'*w)
		# 	}
		# 	win.refresh
		# 	sleep 0.005
		# }
		
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

	# 消したブロックの行数を返す
	remove_lines.size

end

# ゲームオーバー判定
def gameover?
	$block.each_with_index.any?{|l, i|
		l.each_with_index.any?{|e, j|
			e == 1 && $stage[i+$top][j+$left] == 1
		}
	}
end

# ゲームオーバー時のアニメーション
def gameover_anime win
	H.downto(1){|i|
		win.setpos(i, 1)
	    win.addstr('回'*W)
	    sleep 0.08
	    win.refresh
	}
end

begin
    win = Curses::Window.new(H+2, (W+1)*2, 1, 2)
    win.box(?|,'-',?+)
    win.nodelay = 1

    init_block
    loop{
    	# 画面表示
	    display(win)

	    # ゲームオーバーなら
	    if gameover?
		    gameover_anime win
	    	exit
	    end

	    # 落下できるなら
	    if valid?(1, 0)
	    	# 落下する
		    $top += 1
		    # 落下時間まちながらタイプもできる
			type_wait(win, DROP_TIME)
		else
			# 接着待ち
			type_wait(win, PUT_TIME)
			# 待ったあとに下があるなら
			if !valid?(1, 0)
				# 接着する
				$stage = put_block_stage
				# ブロックをけす
				remove_block(win)
				# 次のブロック作成
				init_block
			end
		end	   	
	    
	}

	win.nodelay = 0
    win.getch
    win.close
ensure
    Curses.close_screen
end