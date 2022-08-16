using TileSims
using Documenter

DocMeta.setdocmeta!(TileSims, :DocTestSetup, :(using TileSims); recursive=true)

makedocs(;
    modules=[TileSims],
    authors="Constantine Evans <const@costi.eu> and contributors",
    repo="https://github.com/cgevans/TileSims.jl/blob/{commit}{path}#{line}",
    sitename="TileSims.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cgevans.github.io/TileSims.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/cgevans/TileSims.jl",
    devbranch="main",
)
