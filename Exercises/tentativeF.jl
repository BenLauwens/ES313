### A Pluto.jl notebook ###
# v0.16.1

using Markdown
using InteractiveUtils

# ╔═╡ f96a2802-2b50-11ec-270d-355639ff9f87
begin
	using Pkg
	cd(joinpath(dirname(@__FILE__),".."))
    Pkg.activate(pwd())
end

# ╔═╡ 602d509e-1775-464f-a438-3f9abc3f0060
# erreur could not load library libGR.dll

# ╔═╡ bd156478-54b6-4085-b50e-0b72da4cab28
begin
	struct Cell
		etat::Int
		age::Int
	end
	
	const interpretation = Dict(0=>"bord", 1=>"agriculture",2=>"forêt", 3=>"nature", 4=>"urbain")
	
	Base.show(io::IO, c::Cell) = print(io, "$(interpretation[c.etat]) ($(c.age))")
	
	Base.zero(::Type{Cell}) = Cell(0,0)
	Base.one(::Type{Cell}) = Cell(1,1)
	
	"""
		endroitvoisins(i,j)
	
	pour le tuple d'indices (i,j) rend les indices des voisins autour
	"""
	endroitvoisins(i::Int,j::Int) = CartesianIndex.(Iterators.filter(x-> x[1]≠i || x[2] ≠ j,Iterators.product(i-1:i+1, j-1:j+1)))
	
	tanh_u(c::Cell) = tanh((c.age + 1/2) / 40)
	
	const c_status = Dict(1 => 1/4, 3 => 1/2, 2 => 1/8)
	
	urbanise(c::Cell, voisins::Vector{Cell}) = c_status[c.etat]/8*sum(map(tanh_u, filter(x->isequal(x.etat, 4), voisins)))
		
	function urbanisation(c::Cell, voisins::Vector{Cell})
		# probabilité de changer
		p_trans = urbanise(c, voisins)
		# aspect random
		if rand() < p_trans
			# on change
			return Cell(4, 0)
		else
			# on reste
			return Cell(c.etat, c.age + 1)
		end
	end
	
	tanh_u(c::Cell) = tanh(c.age/10)
	
	function ruralisation(c::Cell, voisins::Vector{Cell})
		# nature => forêt
		if isequal(c.etat,3)
			p_trans = 1/9 * (1 + length(filter(x->isequal(x.etat, 3), voisins))) * tanh( c.age/20)
			if rand() <= p_trans
				return Cell(2, 0)
			end
		# agriculture => nature
		elseif isequal(c.etat,1)
			p_trans = 1/8 * sum(map(tanh_u, filter(x->isequal(x.etat, 1), voisins)))
		else
			return Cell(c.etat, c.age + 1)
		end
	end
	
	# créer un monde
	function monde(m::Int,n::Int)
		M = zeros(Cell, m,n)
		M[2:end-1, 2:end-1] = reshape([Cell(rand(1:4),0) for _ in 1:(m-2)*(n-2)], m-2,:)
		return M
	end
end

# ╔═╡ 682235f8-d1d2-448a-be19-28dc6d5b13b6
let
	m = 3
	n = 6
	temp = [Cell(rand(1:4),0) for _ in 1:(m-2)*(n-2)]
	reshape(temp, m-2,:)
end

# ╔═╡ 3cb7af07-3805-40b1-a3f2-210c7e51b5e2
monde(4,6)

# ╔═╡ 2c888568-e2d1-48fb-8dfc-7c712b59a4e2
	# urbanisation
	testvec = [Cell(rand(0:4), 10) for _ in 1:8]

# ╔═╡ 6070929b-e9c7-45c7-84d8-0420e84dc280
urbanise(Cell(2,100), testvec)

# ╔═╡ 11cc6324-c6c3-4035-af7d-e14498606a24
let
	A = [1;2;3;4]
	@info filter(x-> x<=2, A), A
	@info filter!(x-> x<=2, A), A
end

# ╔═╡ e7f68f47-feee-49f8-95c9-003442038974
let
	i = 2
	j = 5
	
end

# ╔═╡ f294e00e-bb93-4751-bc07-ad5335c7340d
A = ones(Cell, 10,10)

# ╔═╡ 0189941a-72e1-4461-af22-c9b3eaef70af
map(x->x.age, A)

# ╔═╡ Cell order:
# ╠═602d509e-1775-464f-a438-3f9abc3f0060
# ╠═f96a2802-2b50-11ec-270d-355639ff9f87
# ╠═bd156478-54b6-4085-b50e-0b72da4cab28
# ╠═682235f8-d1d2-448a-be19-28dc6d5b13b6
# ╠═3cb7af07-3805-40b1-a3f2-210c7e51b5e2
# ╠═2c888568-e2d1-48fb-8dfc-7c712b59a4e2
# ╠═6070929b-e9c7-45c7-84d8-0420e84dc280
# ╠═11cc6324-c6c3-4035-af7d-e14498606a24
# ╠═e7f68f47-feee-49f8-95c9-003442038974
# ╠═f294e00e-bb93-4751-bc07-ad5335c7340d
# ╠═0189941a-72e1-4461-af22-c9b3eaef70af
