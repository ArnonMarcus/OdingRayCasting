package application

Sample :: [4]Pixel;
Samples :: Grid(Sample);
Texture :: struct {
	bitmaps: []^Bitmap
	samples: []^Samples
}

generateMipMaps :: proc(mipmaps: ^[]^Bitmap) {
	src := mipmaps[0];
	trg := mipmaps[1];
	pixel, temp: vec4;

	for i in 1..<len(mipmaps) {
		trg = mipmaps[i];
		
		for y in 0..<trg.height do
			for x in 0..<trg.width {
				setPixel(&pixel, &src.cells[2*y    ][2*x    ]);
				setPixel(&temp , &src.cells[2*y    ][2*x + 1]); pixel += temp;
				setPixel(&temp , &src.cells[2*y + 1][2*x    ]); pixel += temp;
				setPixel(&temp , &src.cells[2*y + 1][2*x + 1]); pixel += temp;
				
				pixel /= 4;
				setPixel(&trg.cells[y][x], &pixel);
			}

		src = trg;
	}
}

generateSamplesFromBitmap :: proc(samples: ^Samples, using bitmap: ^Bitmap, smear_edges: bool = true, wrap_edges: bool = false) {
	tl, tr, bl, br: ^vec4;
	
	i: [4]i32; 

	T,
	B: i32;
	B = width;

	L: i32;
	BR: i32 = size - 1;
	R: i32 = width - 1;
	BL: i32 = BR - R;
	__: i32 = -1;

	x, y,
	X, Y: i32;

	for row, row_index in &samples.cells {
		Y = i32(row_index);
		y = Y - 1;

		for sample, column_index in &row {
			X = i32(column_index);
			x = X - 1;

			i = {T+x, T+x+1,
				 B+x, B+x+1};

			if wrap_edges {
				if (X == 0 || X == width) {  
					if (Y == 0 || Y == height) do i = { // TL/TR/BL/BR
						BR, BL,
				        R,  L
				    }; else do i = { // L/R:
				    	T+R, T,  
				    	B+R, B
				    };
				} else if (Y == 0 || Y == height) do i = { // T/B
					BL+x, BL+x+1,
				    x,    x+1
				};
			} else if smear_edges {
				if Y == 0 {
					if X == 0 do i = { // TL
						L, L,
				        L, L
				    }; else if X == width do i = { // TR
						R, R,
				        R, R
				    }; else do i = { // T
						x, x+1,
				        x, x+1
					};
				} else if Y == height {
					if X == 0 do i = { // BL
						BL, BL,
				        BL, BL		
					}; else if X == width do i = { // BR
						BR, BR,
				        BR, BR
					}; else do i = { // B
						BL+x, BL+x+1,
				        BL+x, BL+x+1
					};
				} else { 
					if X == 0 do i = { // T
						T, T,
				        B, B
					}; else if X == width do i = { // R
						T+R, T+R,
				        B+R, B+R
					};
				}
			} else {
				if Y == 0 { 
					if X == 0 do i = { // TL
						__, __,
				        __, L		
					}; else if X == width do i = { // TR
						__, __,
				        R, __
					}; else do i = { // T
						__, __,
				        x, x+1
					};
				} else if Y == height { 
					if X == 0 do i = { // BL
						__, BL,
				        __, __		
					}; else if X == width do i = { // BR
						BR, __,
				        __,  __
					}; else do i = { // B
						BL+x, BL+x+1,
				        __,    __ 
					};
				} else { 
					if X == 0 do i = { // L
						__, T,
				        __, B
					}; else if X == width do i ={ // R
						T+R, __,
				        B+R, __
					};
				}
			}

			if i[0] == __ do tl = &BLACK else do tl = &bitmap._cells[i[0]];
			if i[1] == __ do tr = &BLACK else do tr = &bitmap._cells[i[1]];
			if i[2] == __ do bl = &BLACK else do bl = &bitmap._cells[i[2]];
			if i[3] == __ do br = &BLACK else do br = &bitmap._cells[i[3]];
			sample = {
				tl^, tr^,
				bl^, br^
			};
		}

		if Y != 0 {
			T = B;
			B += width;
		}
	}
}

generateTextureSamples :: proc(using texture: ^Texture, smear_edges: bool = true, wrap_edges: bool = false) do
	for bitmap, mip in &bitmaps do 
		generateSamplesFromBitmap(samples[mip], bitmap, smear_edges, wrap_edges);

sample2 :: inline proc(using samples: ^Samples, u, v: f32, out: ^$Out) {
	U := u * f32(width ) - 0.5;
	V := v * f32(height) - 0.5;
	
 	x := i32(U);
 	y := i32(V);

	r := U - f32(x); 
	b := V - f32(y);   
	
	l := 1 - r;
	t := 1 - b;

	// tl := t * l;    tr := t * r;
	// bl := b * l;    br := b * r;

	samples := &cells[y][x];

	// using samples;
	top := samples[0] * l + samples[1] * r;
	bottom := samples[2] * l + samples[3] * r;
	out^ = top * t + bottom * b;

	// out.R = u8(result.r);
	// out.G = u8(result.g);
	// out.B = u8(result.b);
	// out.a = u8(result.a);
}
sample :: inline proc(using samples: ^Samples, u, v: f32, out: ^$Out) {
	U := u * f32(width ) - 0.5; x := i32(U);
	V := v * f32(height) - 0.5; y := i32(V);
	r := U - f32(x); l := 1 - r;
	b := V - f32(y); t := 1 - b;

	samples := &cells[y][x];
	// using samples;
	// color^ = TL*t*l + TR*t*r + BL*b*l + BR*b*r;
	out^ = samples[0]*t*l + samples[0]*t*r + samples[2]*b*l + samples[3]*b*r;
}

sampleTexture :: inline proc(texture: ^Texture, mip_level: u8, u, v: f32, out: ^$Out) do _sample(texture.samples[mip_level], u, v, out);

scaleTexture :: proc(from: ^Samples, to: ^$S/Grid) {
	for y in 0..<to.height do
		for x in 0..<to.width do
			sample(from, f32(x)/f32(to.width), f32(y)/f32(to.height), &to.cells[y][x]);
}

loadTexture :: proc(using texture: ^Texture, file: ^[]u8, smear_edges: bool = true, wrap_edges: bool = false) {
	readBitmapFromFile(bitmaps[0], file, bitmaps[0]._cells);
	generateMipMaps(&bitmaps);
	generateTextureSamples(texture, smear_edges, wrap_edges);
}