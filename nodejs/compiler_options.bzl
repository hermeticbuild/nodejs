"""Compiler options shared by Node.js targets."""

def cxx20_copts():
    """Returns the C++20 option for the selected compiler."""
    return select({
        "@rules_cc//cc/compiler:clang-cl": ["/std:c++20"],
        "//conditions:default": ["-std=c++20"],
    })
