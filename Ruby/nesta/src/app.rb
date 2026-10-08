# Nesta reads metadata from a "Key: value" header block. The SSGBerk content model
# writes YAML front matter ("3minus"), so this local override (Nesta loads ./app.rb
# itself) teaches the page loader that format. It runs in-process while the pages are
# read, so the timed build has no pre-processing step.
require "yaml"
require "time"

module SsgberkFrontMatter
  FRONT_MATTER = /\A---\r?\n(.*?\r?\n)---\r?\n/m

  private

  def parse_file
    contents = File.read(@filename)
    match = FRONT_MATTER.match(contents)
    return super unless match

    data = YAML.safe_load(match[1], permitted_classes: [Time, Date]) || {}
    metadata = Nesta::FileModel::CaseInsensitiveHash.new
    data.each do |key, value|
      metadata[key.to_s.downcase] =
        case value
        when Array then value.join(", ")
        when Time then value.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        else value.to_s
        end
    end
    [metadata, match.post_match]
  end
end

Nesta::FileModel.prepend(SsgberkFrontMatter)
