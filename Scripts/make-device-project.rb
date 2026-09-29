#!/usr/bin/env ruby
# Development host: product sources remain SwiftPM libraries with no C++ dependency.
require 'xcodeproj'
require 'pathname'
root = Pathname.new(__dir__).parent.realpath
folder = root + 'Benchmarks/.build/device'
folder.mkpath
# Compile the exact CLI workload inside a callable function; no independent device port.
native = (root + 'Benchmarks/Sources/YogaBenchmarks/main.swift').read
native = native.sub("let arguments = CommandLine.arguments", "")
native = native.sub("import BenchmarkMetrics\n", "")
native = native.sub("let workload =", "@MainActor func runNativeBenchmark(arguments: [String]) throws -> String {\nlet workload =")
native = native.gsub(/print\(String\(decoding: (.*), as: UTF8.self\)\)/, 'return String(decoding: \1, as: UTF8.self)')
native = native.sub("withExtendedLifetime(trees) { return", "return withExtendedLifetime(trees) { return")
native += "\n}\n"
(folder + 'NativeBenchmark.swift').write(native)
project = Xcodeproj::Project.new((folder + 'YogaValidation.xcodeproj').to_s)
project.root_object.attributes['LastUpgradeCheck'] = '2700'
package = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package.relative_path = root.relative_path_from(folder).to_s
project.root_object.package_references << package
app = project.new_target(:application, 'YogaValidation', :ios, '16.0')
tests = project.new_target(:unit_test_bundle, 'YogaValidationTests', :ios, '16.0')
tests.add_dependency(app)
app.source_build_phase.add_file_reference(project.main_group.new_file((root + 'Benchmarks/DeviceValidation/ValidationApp.swift').to_s))
Dir.glob((root + 'Tests/{YogaTests,YogaSwiftUITests}/*.swift').to_s).sort.each do |path|
  tests.source_build_phase.add_file_reference(project.main_group.new_file(path))
end
tests.resources_build_phase.add_file_reference(project.main_group.new_file((root + 'Tests/YogaTests/Fixtures/yoga-3.2.1.json').to_s))
[app,tests].each do |consumer|
['Yoga', 'YogaSwiftUI'].each do |name|
  dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.package = package
  dep.product_name = name
  consumer.package_product_dependencies << dep
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = dep
  consumer.frameworks_build_phase.files << build_file
end
end
[app,tests].each do |target|
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'SWIFT_VERSION'=>'6.0', 'SWIFT_STRICT_CONCURRENCY'=>'complete',
      'GENERATE_INFOPLIST_FILE'=>'YES', 'CODE_SIGN_STYLE'=>'Automatic',
      'PRODUCT_BUNDLE_IDENTIFIER'=>"com.tiepvuvan.yogaswiftui.#{target.name.downcase}",
      'TARGETED_DEVICE_FAMILY'=>'1,2', 'IPHONEOS_DEPLOYMENT_TARGET'=>'16.0',
      'SWIFT_OPTIMIZATION_LEVEL'=>config.name == 'Release' ? '-O' : '-Onone',
      'SWIFT_COMPILATION_MODE'=>'wholemodule'
    })
  end
end
app.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation']='YES'
end
tests.build_configurations.each do |config|
  config.build_settings['TEST_HOST']='$(BUILT_PRODUCTS_DIR)/YogaValidation.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/YogaValidation'
  config.build_settings['BUNDLE_LOADER']='$(TEST_HOST)'
end
reference = ARGV[0] ? Pathname.new(ARGV[0]).realpath : root + '.build/checkouts/yoga'
expected = '042f5013152eb81c1552dec945b88f7b95ca350f'
abort 'Wrong reference revision' unless IO.popen(['git','-C',reference.to_s,'rev-parse','HEAD'], &:read).strip == expected
sources = [(folder + 'NativeBenchmark.swift'), (root + 'Benchmarks/DeviceValidation/DeviceBenchmark.swift'),
           (root + 'Benchmarks/DeviceValidation/ReferenceRunner.cpp'),
           (root + 'Benchmarks/Sources/BenchmarkMetrics/BenchmarkMetrics.c')]
sources += Dir.glob((reference + 'yoga/**/*.cpp').to_s).sort.map { |p| Pathname.new(p) }
sources.each { |path| app.source_build_phase.add_file_reference(project.main_group.new_file(path.to_s)) }
app.build_configurations.each do |config|
  config.build_settings.merge!({
    'SWIFT_OBJC_BRIDGING_HEADER'=>(root + 'Benchmarks/DeviceValidation/ValidationBridge.h').to_s,
    'HEADER_SEARCH_PATHS'=>['$(inherited)', reference.to_s, (root + 'Benchmarks').to_s,
                          (root + 'Benchmarks/Sources/BenchmarkMetrics/include').to_s],
    'CLANG_CXX_LANGUAGE_STANDARD'=>'c++20', 'CLANG_CXX_LIBRARY'=>'libc++',
    'GCC_OPTIMIZATION_LEVEL'=>'3', 'LLVM_LTO'=>'YES',
    'GCC_PREPROCESSOR_DEFINITIONS'=>['$(inherited)', 'NDEBUG=1'],
    'OTHER_LDFLAGS'=>['$(inherited)', '-lc++']
  })
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(tests)
scheme.set_launch_target(app)
scheme.test_action.build_configuration = 'Release'
scheme.save_as(project.path, 'YogaValidation', true)
puts project.path
