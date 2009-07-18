class BoundsIntegrator
	ATTRACTION = 0.2
	DAMPING    = 0.5
	attr_accessor :x, :y, :w, :h,
	              :attraction, :damping

	def initialize(x = 0, y = 0, w = 1, h = 1)
		@velocity_x = @acceleration_x =
		@velocity_y = @acceleration_y =
		@velocity_w = @acceleration_w =
		@velocity_h = @acceleration_h = 0

		@x = x
		@y = y
		@w = w
		@h = h
		@damping    = DAMPING
		@attraction = ATTRACTION
	end

	def set(x = 0, y = 0, w = 1, h = 1)
		@x = x
		@y = y
		@w = w
		@h = h
	end

	def span_x(point_x, start, span)
		return nil if @w == 0
		n = (point_x - @x) / @w
		start + n * span
	end

	def span_y(point_y, start, span)
		return nil if @h == 0
		n = (point_y - @y) / @h
		start + n * span
	end

	def update
		if @targeting then
			@acceleration_x += @attraction * (@target_x - @x)
			@velocity_x = (@velocity_x + @acceleration_x) * @damping
			@x += @velocity_x
			@acceleration_x = 0
			updated = @velocity_x.abs > 0.0001

			@acceleration_y += @attraction * (@target_y - @y)
			@velocity_y = (@velocity_y + @acceleration_y) * @damping
			@y += @velocity_y
			@acceleration_y = 0
			updated |= @velocity_y.abs > 0.0001

			@acceleration_w += @attraction * (@target_w - @w)
			@velocity_w = (@velocity_w + @acceleration_w) * @damping
			@w += @velocity_w
			@acceleration_w = 0
			updated |= @velocity_w.abs > 0.0001

			@acceleration_h += @attraction * (@target_h - @h)
			@velocity_h = (@velocity_h + @acceleration_h) * @damping
			@h += @velocity_h
			@acceleration_h = 0
			updated |= @velocity_h.abs > 0.0001
		else
			false
		end
	end

	def target(tx, ty, tw, th)
		@targeting = true
		@target_x  = tx
		@target_y  = ty
		@target_w  = tw
		@target_h  = th
	end

	def target_location(tx, ty)
		@targeting = true
		@target_x  = tx
		@target_y  = ty
	end

	def target_size(tw, th)
		@targeting = true
		@target_w  = tw
		@target_h  = th
	end

	def target_x=(tx)
		@targeting = true
		@target_X  = tx
	end

	def target_y=(ty)
		@targeting = true
		@target_y  = ty
	end

	def target_w=(tw)
		@targeting = true
		@target_W = tw
	end

	def target_h=(th)
		@targeting = true
		@target_h  = th
	end
end
