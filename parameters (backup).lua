--Reaction-Diffusion
DO = 2.41e-5	--cm^2/s (oxigen diffusion)
Okv = 1.16e-3	--mol/l/s (oxigen production rate)
Opc = 3.47e-4	--s^-1 (oxigen consumption rate for proliferative)
Oqc = Opc/2		--s^-1 (oxigen consumption rate for quiescent)
O0 = 1			--mol/l (initial oxygen)
DG = DO			--cm^2/s (glucose diffusion)
Gkv = Okv		--mol/l/s (glucose production rate)
Gpc = Opc		--s^-1 (glucose consumption rate for proliferative)
Gqc = Gpc		--s^-1 (glucose consumption rate for quiescent)
G0 = 1			--mol/l (initial glucose)
DB = DO			--cm^2/s (bevacizumab diffusion)
Bkv = Okv*1.0	--mol/l/s (bevacizumab production rate [1.0-1.1])
Bpc = Opc		--s^-1 (bevacizumab consumption rate for proliferative)
Bqc = Bpc		--s^-1 (bevacizumab consumption rate for quiescent)
B0 = 0			--mol/l (initial bevacizumab)

--Cellular Automaton
Op = 0.4		--mol/l (minimum oxygen for proliferative)
Oq = 0.2		--mol/l (minimum oxygen for quiescent)
Gt = 0.2		--mol/l (minimum glucose)
Ba = 0.1		--mol/l (maximum bevacizumab for angiogenesis)
Bv = 0.15		--mol/l (maximum bevacizumab for vessels [0.1-0.2])
Td = 24			--h (division time)
Tm = 24			--h (migration time)
Ta = 72			--h (angiogenesis time)
Tn = 48			--h (necrosis removal time)

--Misc
itDay = 100		--iterations per day
cmPixel = 0.07	--cm per pixel
