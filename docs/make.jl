using YAZXCalculusTutorials
using Documenter

DocMeta.setdocmeta!(YAZXCalculusTutorials, :DocTestSetup, :(using YAZXCalculusTutorials); recursive=true)

makedocs(;
    modules=[YAZXCalculusTutorials],
    authors="Yusheng Zhao <yushengzhao2020@outlook.com> and contributors",
    repo="https://github.com/exAClior/YAZXCalculusTutorials.jl/blob/{commit}{path}#{line}",
    sitename="YAZXCalculusTutorials.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://exAClior.github.io/YAZXCalculusTutorials.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/exAClior/YAZXCalculusTutorials.jl",
    devbranch="main",
)
