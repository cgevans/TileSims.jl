module TileSims

export Tilesystem, Parameters, Tile, Glue, Interaction, InitState

using DataStructures

@enum TileShape single vertical horizontal
@enum GlueType matching complement

XGROWBINARY = read(open(`python -c "import xgrow; print(xgrow.xgrow._XGROW_BINARY)"`), String)[1:end-1]

struct Tile
    edges::Vector{Union{String,Int}}
    name::Union{String,Nothing}
    stoic::Real
    color::Union{String,Nothing}
    shape::TileShape
end
Tile(edges, name, stoic, color) = Tile(edges, name, stoic, color, single)
Tile(edges, name) = Tile(edges, name, 1, nothing)
Tile(edges) = Tile(edges, nothing)

struct Glue
    name::String
    strength::Real
end
Glue(name) = Glue(name, 1)

struct Interaction
    bond1::Union{String,Int}
    bond2::Union{String,Int}
    strength::Real
end

InitState = Vector{Tuple{Int, Int, Union{String,Int}}}

struct Tilesystem
    tiles::Vector{Tile}
    glues::Vector{Glue}
    interactions::Vector{Interaction}
    initstate::InitState
    gluetype::GlueType
    params::Dict{String, Any}
end

struct ConcreteTilesystem
    tile_names::Vector{String}
    tile_edges::Array{Int, 2}
    tile_stoics::Vector{Float64}
    tile_colors::Vector{Union{String, Nothing}}
    hdoubles::Vector{Tuple{Int, Int}}
    vdoubles::Vector{Tuple{Int, Int}}
    bond_names::Vector{String}
    interactions::Array{Float64, 2}
    initstate::Vector{Tuple{Int,Int,Int}}
    params::Dict{String, Any}
end

function to_concrete(ts::Tilesystem)
    gluenames = OrderedDict{String, Int}()
    gluestrengths = OrderedDict{String, Float64}()

    # String 0 is also 0 / null glue.
    push!(gluenames, "0" => 0)
    push!(gluestrengths, "0" => 0.0)

    # Collect explicit glue names
    glue_i = 1
    for glue in ts.glues
        if haskey(gluenames, glue.name)
            continue
        end
        if ts.gluetype == complement
            push!(gluenames, gluebasename(glue.name) => glue_i)
            push!(gluenames, gluebasecompname(glue.name) => glue_i+1)
            push!(gluestrengths, gluebasename(glue.name) => glue.strength)
            glue_i += 2
        else
            push!(gluenames, glue.name => glue_i)
            push!(gluestrengths, glue.name => glue.strength)
            glue_i += 1
        end
    end
    
    nhduples = 0
    nvduples = 0
    for (tile_i, tile) in enumerate(ts.tiles)
        # Collect glue names
        for (edge_i, edge) in enumerate(tile.edges)
            if (typeof(edge) == String) & !haskey(gluenames, edge)
                if ts.gluetype == complement
                    push!(gluenames, gluebasename(edge) => glue_i)
                    push!(gluenames, gluebasecompname(edge) => glue_i+1)
                    push!(gluestrengths, gluebasename(edge) => 1.0)
                    glue_i += 2
                else
                    push!(gluenames, edge)
                    push!(gluestrengths, edge => 1.0)
                    glue_i += 1
                end
            end
        end
        if tile.shape == horizontal
            nhduples += 1
        elseif tile.shape == vertical
            nvduples += 1
        end
    end

    ntiles = length(ts.tiles) + nhduples + nvduples
    tile_edges = Array{Int, 2}(undef, (ntiles, 4))
    tile_names = Vector{String}(undef, ntiles)
    tile_stoics = Vector{Float64}(undef, ntiles)
    tile_colors = Vector{Union{String, Nothing}}(undef, ntiles)
    hdoubles = Vector{Tuple{Int, Int}}(undef, nhduples)
    vdoubles = Vector{Tuple{Int, Int}}(undef, nvduples)

    hduple_i = 1
    vduple_i = 1
    duple_i = length(ts.tiles)+1
    for (tile_i, tile) in enumerate(ts.tiles)
        # If we're a single, just add glues
        if tile.shape == single
            for (edge_i, edge) in enumerate(tile.edges)
                if typeof(edge) == String
                    tile_edges[tile_i, edge_i] = gluenames[edge]
                else
                    tile_edges[tile_i, edge_i] = edge
                end
            end
        elseif tile.shape == horizontal
            hdoubles[hduple_i] = (tile_i, duple_i)
            for (i,j) in [(1,1), (3,5), (4,6)]
                edge = tile.edges[j]
                if typeof(edge) == String
                    tile_edges[tile_i, i] = gluenames[edge]
                else
                    tile_edges[tile_i, i] = edge
                end
            end
            gluenames[tile.name*"_fakedt"] = glue_i
            gluestrengths[tile.name*"_fakedt"] = 1
            tile_edges[tile_i, 2] = glue_i
            tile_edges[duple_i, 4] = glue_i
            tile_stoics[duple_i] = tile.stoic
            tile_colors[duple_i] = tile.color
            tile_names[duple_i] = tile.name * "_right"
            for (i,j) in [(1,2), (2,3), (3,4)]
                edge = tile.edges[j]
                if typeof(edge) == String
                    tile_edges[duple_i, i] = gluenames[edge]
                else
                    tile_edges[duple_i, i] = edge
                end
            end
            hduple_i += 1
            duple_i += 1
            glue_i += 1
        elseif tile.shape == vertical
            vdoubles[vduple_i] = (tile_i, duple_i)
            for (i,j) in [(1,1), (2,2), (4,6)]
                edge = tile.edges[j]
                if typeof(edge) == String
                    tile_edges[tile_i, i] = gluenames[edge]
                else
                    tile_edges[tile_i, i] = edge
                end
            end
            gluenames[tile.name*"_fakedt"] = glue_i
            gluestrengths[tile.name*"_fakedt"] = 1
            tile_edges[tile_i, 3] = glue_i
            tile_edges[duple_i, 1] = glue_i
            tile_stoics[duple_i] = tile.stoic
            tile_colors[duple_i] = tile.color
            tile_names[duple_i] = tile.name * "_bottom"
            for (i,j) in [(2,3), (3,4), (4,5)]
                edge = tile.edges[j]
                if typeof(edge) == String
                    tile_edges[duple_i, i] = gluenames[edge]
                else
                    tile_edges[duple_i, i] = edge
                end
            end
            glue_i += 1
            vduple_i += 1
            duple_i += 1
        else
            error("Unknown shape")
        end

        tile_names[tile_i] = tile.name
        tile_colors[tile_i] = tile.color
        tile_stoics[tile_i] = tile.stoic
    end

    nglues = length(gluenames)-1 # excludes null
    interactions = zeros(Float64, (nglues+1,nglues+1))

    initstate = []
    for (x,y,t) in ts.initstate
        if typeof(t) == String
            t = findfirst(isequal(t), tile_names) # FIXME: faster?
        end
        push!(initstate, (x,y,t))
    end

    for (glue, v) in gluenames
        if ts.gluetype == matching
            interactions[v+1,v+1] = gluestrengths[glue]
        elseif ts.gluetype == complement
            interactions[v+1, gluenames[gluecompname(glue)]+1] = gluestrengths[gluebasename(glue)]
        end
    end

    return ConcreteTilesystem(tile_names, tile_edges, tile_stoics, tile_colors, hdoubles, vdoubles, collect(keys(gluenames))[2:end], interactions, initstate, ts.params)
end

function gluebasename(x::String)::String
    if endswith(x, '*')
        return x[1:end-1]
    else
        return x
    end
end

function gluecompname(x::String)::String
    if endswith(x, '*')
        return x[1:end-1]
    elseif x == "0"
        return "0"
    elseif endswith(x, "fakedt")
        return x
    else
        return x * "*"
    end
end

function gluebasecompname(x::String)::String
    if endswith(x, '*')
        return x
    else
        return x * "*"
    end
end    

function run_xgrow(ts::Tilesystem)
    run_xgrow(to_concrete(ts))
end

function run_xgrow(cts::ConcreteTilesystem)
    path = Base.Filesystem.tempname()
    f = open(path, "w")
    if length(cts.initstate) > 0
        initpath = Base.Filesystem.tempname()
        initfile = open(initpath, "w")
    else
        initfile = nothing
    end
    write_xgrow_file(cts, f; initfile=initfile)
    close(f)
    if initfile !== nothing
        close(initfile)
        importstring = "importfile=$(initpath)"
    else
        importstring = ""
    end
    run(`$(XGROWBINARY) $(path) $(importstring)`)
end

function write_xgrow_file(cts::ConcreteTilesystem, io::IO; usenames::Bool = false, initfile::Union{IO,Nothing}=nothing)
    write(io, "num tile types=$(length(cts.tile_names))\n")
    write(io, "num binding types=$(length(cts.bond_names))\n")

    write(io, "binding type names={")
    join(io, cts.bond_names , " ")
    write(io, "}\n\n")

    write(io, "tile edges={\n")
    for i in 1:length(cts.tile_names)
        write(io, "{")
        if usenames
            join(io, (cts.bond_names[x] for x in cts.tile_edges[i, :]), " ")            
        else
            join(io, cts.tile_edges[i, :], " ")
        end
        write(io, "}")
        if cts.tile_stoics[i] != 1
            write(io, "[$(cts.tile_stoics[i])]")
        end
        if cts.tile_colors[i] !== nothing
            write(io, "($(cts.tile_colors[i]))")
        end
        if cts.tile_names[i] !== nothing
            write(io, "<$(cts.tile_names[i])>")
        end
        write(io, "\n")
    end
    write(io, "}\n\n")

    write(io, "binding strengths={")

    join(io, (cts.interactions[i,i] for i in 2:(length(cts.bond_names)+1)), " ")

    write(io, "}\n\n")

    # for (x,y,t) in cts.initstate
    #     write(io, "i($(x),$(y))=$(t)\n")
    # end

    for I in CartesianIndices(cts.interactions)
        if (I[1] != I[2]) & (cts.interactions[I] != 0)
            write(io, "g($(I[1]-1), $(I[2]-1))=$(cts.interactions[I])\n")
        
        end
    end

    for (t1,t2) in cts.hdoubles
        write(io, "doubletile=$t1,$t2\n")
    end

    for (t1,t2) in cts.vdoubles
        write(io, "vdoubletile=$t1,$t2\n")
    end

    for (k, v) in cts.params
        write(io, "$k=$v\n")
    end

    if (length(cts.initstate) > 0) & (initfile !== nothing)
        write(initfile, "flake{1}={ ...\n[ 0 0 0 0 0 0 0 0 0 0 ],...\n[ 1 1 1 ],...\n")
        canvassize = get(cts.params, "size", 128)
        canvas = zeros(Int, (canvassize, canvassize))
        for (x,y,t) in cts.initstate
            canvas[x,y] = t
        end
        for x in 1:canvassize
            if x == 1
                write(initfile, "[ ")
            else
                write(initfile, "  ")
            end
            join(initfile, (string(i) for i in canvas[x,:]), " ")
            write(initfile, "; ...\n")
        end
        write(initfile, "] };\n")            
    end

end

end