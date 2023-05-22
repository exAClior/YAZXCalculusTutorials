### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# ╔═╡ f7bead88-f85d-11ed-30ec-9b8623e92199
let
    using Pkg
    Pkg.activate(".")
end

# ╔═╡ 12450be9-1c69-4c1f-8fa6-b812d18855f4
let
    using ZXCalculus, Revise, LightGraphs, Multigraphs, YaoPlots, Compose, Yao, StatsBase
end


# ╔═╡ 2944f871-c22e-45f1-8acb-6fdb9af522bf
md"
   # First time creating a ZX diagram
       We will create a multigraph first. Then, we will
     create a ZXDiagram from it by assigning different
     spider types to vertices.

"

# ╔═╡ 497aa631-b079-4c69-8c09-e4ba3d8c2061
begin
    g = Multigraph(6)

    Multigraphs.add_edge!(g, 1, 3)
    Multigraphs.add_edge!(g, 2, 4)
    Multigraphs.add_edge!(g, 3, 4)
    Multigraphs.add_edge!(g, 3, 5)
    Multigraphs.add_edge!(g, 4, 6)

end

# ╔═╡ ffc6ef80-1084-4830-80f0-013adc126741
begin
    # phases of the spiders
    ps = [0 // 1 for i = 1:6]

    # define types of spiders
    # two in wires (may connect to quantum state)
    # one X spider, one Z spider
    # two out wires (may connect to quantum measurement)
    v_t = [SpiderType.In, SpiderType.In, SpiderType.X, SpiderType.Z, SpiderType.Out, SpiderType.Out]

    zxd_from_multigraph = ZXDiagram(g, v_t, ps)
end

# ╔═╡ aad51c0c-55f8-4d0d-abfc-9104f2b3a258
zx_diag = compose(context(0.0, 0.0, 1.0, 1.0), plot(zxd_from_multigraph))

# ╔═╡ fecba9e8-923b-40bc-a6da-2aca34811d60
md"
## Explain displayed diagram
- Notice in-wires are denoted with cyan color while out-wires are denoted with grey color.
- Phase of each spider is denoted with a number on the spider.
"

# ╔═╡ e2dc2a33-b1b9-4867-b260-9b714fff8f26
md"
# Optimize Yao.jl Blocks
 - we generate a random using Yao.jl's interface
 - Then, we convert it to a ZXDiagram and use ZX-Diagram rewrite rules to simplify it.
## Dependency issues
YaoLang.jl seem to be broken. I will try to use good old
way to make circuit in Yao.jl.

"

# ╔═╡ b9f9097b-266b-40d4-88f0-d2350ef68d74
function random_block(n::Int, ngates::Int)
    # random block
    # n is the number of qubits
    # return a block with n qubits
    # and random gates
    # return a block with n qubits
    # and random gates
    block = chain(n)
    for _ = 1:ngates
        # randomly apply single qubit or two qubit gates
        if rand() < 0.5
            block = chain(n, block, put(rand(1:n) => rand([X, Z, H])))
        else
            ctrl, tgt = sample(1:n, 2; replace=false)
            block = chain(n, block, control(n, ctrl, tgt => rand([X, Z])))
        end
    end
    return YaoBlocks.Optimise.simplify(block)
end

# ╔═╡ 81210460-6c9d-4b05-8194-685bdd70e1d0
begin
    n_qubits = 4
    block_raw = random_block(n_qubits, 50)
    YaoPlots.plot(block_raw)
end

# ╔═╡ 10af7586-5d2c-4429-979d-bc48d2a25268
# copy push_gate! function form
# https://github.com/QuantumBFS/ZXCalculus.jl/blob/bbc19ab5ec0f1eb0b09ffa7a6e2976f60b625fbc/notebooks/tutorial.jl
# modify code to coupe with most recent Yao.jl API
begin
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::AbstractBlock)
        error("Block type `$c` is not supported.")
    end
    # rotation blocks
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::PutBlock{N,1,RotationGate{2,T,XGate}}) where {N,T}
        push_gate!(zxd, Val(:X), c.locs[1], c.content.theta)
    end
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::PutBlock{N,1,RotationGate{2,T,ZGate}}) where {N,T}
        push_gate!(zxd, Val(:Z), c.locs[1], c.content.theta)
    end
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::PutBlock{N,1,ShiftGate{T}}) where {N,T}
        push_gate!(zxd, Val(:Z), c.locs[1], c.content.theta)
    end
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::PutBlock{N,1,HGate}) where {N}
        push_gate!(zxd, Val(:H), c.locs[1])
    end
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::ChainBlock{N}) where {N}
        push_gate!.(Ref(zxd), subblocks(c))
        zxd
    end

    # constant block
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::PutBlock{N,1,XGate}) where N
        push_gate!(zxd, Val(:X), c.locs[1])
    end
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::PutBlock{N,1,ZGate}) where N
        push_gate!(zxd, Val(:Z), c.locs[1])
    end

    # control blocks
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::ControlBlock{XGate,N,1}) where N
        push_gate!(zxd, Val(:CNOT), c.locs[1], c.ctrl_locs[1])
    end
    function ZXCalculus.push_gate!(zxd::ZXDiagram, c::ControlBlock{ZGate,N,1}) where N
        push_gate!(zxd, Val(:CZ), c.locs[1], c.ctrl_locs[1])
    end
    # function ZXCalculus.push_gate!(zxd::ZXDiagram, c::ControlBlock{ShiftGate{T},N,1}) where {N,T}
    # 	push_gate!(zxd, Val(:Z), c.locs[1], c.content.theta)
    # end
end

# ╔═╡ f75280be-0c8c-4c79-be38-e8a35e49f6ba
begin
    # convert from YaoBlock to ZXDiagram
    zx_raw = ZXDiagram(n_qubits)
    for block in block_raw.blocks
        push_gate!(zx_raw, block)
    end
end

# ╔═╡ 9cf6e18a-bd41-495f-b6aa-43dbe75db662
YaoPlots.plot(zx_raw)

# ╔═╡ 47c4fe49-fd15-401c-b91e-b07bc537b66f


# ╔═╡ 39f082e9-d20d-4217-9478-fd55d817a7d9


# ╔═╡ aabf19e6-ed9b-4b07-95a9-f0666b03376c


# ╔═╡ 380fee24-162d-4058-b995-3d207e4eb076
md"
# Generate circuit from ZX-Diagram and simplify
"

# ╔═╡ Cell order:
# ╠═f7bead88-f85d-11ed-30ec-9b8623e92199
# ╠═12450be9-1c69-4c1f-8fa6-b812d18855f4
# ╟─2944f871-c22e-45f1-8acb-6fdb9af522bf
# ╠═497aa631-b079-4c69-8c09-e4ba3d8c2061
# ╠═ffc6ef80-1084-4830-80f0-013adc126741
# ╠═aad51c0c-55f8-4d0d-abfc-9104f2b3a258
# ╟─fecba9e8-923b-40bc-a6da-2aca34811d60
# ╟─e2dc2a33-b1b9-4867-b260-9b714fff8f26
# ╠═b9f9097b-266b-40d4-88f0-d2350ef68d74
# ╠═81210460-6c9d-4b05-8194-685bdd70e1d0
# ╠═10af7586-5d2c-4429-979d-bc48d2a25268
# ╠═f75280be-0c8c-4c79-be38-e8a35e49f6ba
# ╠═9cf6e18a-bd41-495f-b6aa-43dbe75db662
# ╠═47c4fe49-fd15-401c-b91e-b07bc537b66f
# ╠═39f082e9-d20d-4217-9478-fd55d817a7d9
# ╠═aabf19e6-ed9b-4b07-95a9-f0666b03376c
# ╠═380fee24-162d-4058-b995-3d207e4eb076
