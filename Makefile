.PHONY: format lint test check build clean inotes

SWIFT_FORMAT := swift format
SWIFTLINT := swiftlint

format:
	$(SWIFT_FORMAT) --in-place --recursive Sources Tests Package.swift

lint:
	$(SWIFT_FORMAT) lint --recursive Sources Tests Package.swift
	@if command -v $(SWIFTLINT) >/dev/null 2>&1; then \
		$(SWIFTLINT) lint --quiet; \
	else \
		echo "swiftlint not installed; skipping swiftlint (install with: brew install swiftlint)"; \
	fi

test:
	@./scripts/generate-version.sh
	swift test --enable-code-coverage

check: lint test

build:
	@./scripts/generate-version.sh
	swift build -c release --arch arm64 --arch x86_64
	@mkdir -p bin
	@cp "$$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/inotes" bin/inotes
	@codesign --force --sign - --identifier com.wangwalk.inotes bin/inotes
	@echo "Built: bin/inotes"

inotes:
	@./scripts/generate-version.sh
	swift package clean
	swift build
	@echo "--- running inotes $(ARGS) ---"
	@swift run inotes $(ARGS)

clean:
	swift package clean
	rm -rf bin
