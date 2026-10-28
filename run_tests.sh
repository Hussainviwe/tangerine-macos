#!/bin/bash
set -e
swift Sources/Tangerine/Core/FileType.swift Sources/Tangerine/Core/ToolOptions.swift Sources/Tangerine/Core/ConversionEngine.swift Sources/Tangerine/UI/FormatMatrixView.swift Tests/verify.swift
