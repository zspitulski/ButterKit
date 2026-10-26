require "fileutils"

# Lays out fastlane snapshot output the way a ButterKit linked folder likes it.
#
#   fastlane writes:   screenshots/<locale>/<simulator name>-<screenshot name>.png
#   ButterKit reads:   butterkit/<locale>/<ButterKit device>/<screenshot name>.png
#
# Link the destination folder in ButterKit once. Every run refreshes its contents
# in place, and ButterKit picks up the changes.
module ButterKitFolders
  IMAGE_EXTENSIONS = %w[.png .jpg .jpeg].freeze

  # devices maps each simulator name you capture on to a ButterKit device folder
  # name, for example "iPad Pro 13-inch (M4)" => "iPad". Returns the number of
  # images copied.
  def self.organize(source:, destination:, devices:)
    FileUtils.mkdir_p(destination)
    # Empty the folder but keep it, so ButterKit's link to it stays valid.
    Dir.glob(File.join(destination, "*")).each { |path| FileUtils.rm_rf(path) }

    # Longest names first, so "iPhone 17 Pro Max" wins over "iPhone 17 Pro".
    simulators = devices.keys.sort_by { |name| -name.length }
    copied = 0

    Dir.glob(File.join(source, "*")).select { |path| File.directory?(path) }.sort.each do |locale_dir|
      locale = File.basename(locale_dir)
      Dir.glob(File.join(locale_dir, "*")).sort.each do |file|
        next unless IMAGE_EXTENSIONS.include?(File.extname(file).downcase)
        name = File.basename(file)
        # frameit output sits next to the raw screenshots. ButterKit adds its own devices.
        next if name.include?("_framed")
        simulator = simulators.find { |sim| name.start_with?("#{sim}-") }
        next if simulator.nil?

        target = File.join(destination, locale, devices[simulator], name.delete_prefix("#{simulator}-"))
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp(file, target)
        copied += 1
      end
    end

    copied
  end
end
