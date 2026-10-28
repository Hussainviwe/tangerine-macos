#!/bin/bash
set -e
swiftc -parse-as-library Sources/Tangerine/App/AppState.swift Sources/Tangerine/Core/FileType.swift Sources/Tangerine/Core/ToolOptions.swift Sources/Tangerine/Core/ConversionEngine.swift Sources/Tangerine/UI/FormatMatrixView.swift Tests/verify.swift -o /tmp/verify && /tmp/verify
