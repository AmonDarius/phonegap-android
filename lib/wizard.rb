# Wizard
# 
# Walks user through the creation of an Android project
#
class Wizard
  
  def initialize()
    
    @android_sdk_path = `which android`.gsub('/tools/android','').chomp
    
    if @android_sdk_path.empty?
      puts "\nSORRY!\nDroidgap can't find your android installation.\nPlease make sure you have installed the Android SDK and \nadded the tools directory to your PATH.\n\n"
      exit
    end

    puts "\nPublic name for your app (e.g. MyApp):"
    @name = STDIN.gets.chomp

    puts "\nPackage name for your app (e.g. com.example.myapp):"
    @pkg = STDIN.gets.chomp

    puts "\nPath to your web app directory (e.g. the directory that has your HTML, CSS, and JavaScript files):"
    @www = File.expand_path(STDIN.gets.chomp)
    
    until File.directory? @www
      puts "\nSORRY! '#{ @www }' is not a valid directory path. Please try again:"
      @www = File.expand_path(STDIN.gets.chomp)
    end
    
    # TODO validate contents of www directory

    puts "\nPath to directory where droidgap should output your files (NOTE - must not exist):"
    @output_dir = File.expand_path(STDIN.gets.chomp)
    
    while File.exists? @output_dir
      puts "\nSORRY! '#{ @output_dir }' directory already exists. Please specify a directory that does not exist:"
      @output_dir = File.expand_path(STDIN.gets.chomp)
    end

    puts "\nAndroid SDK platform you are targeting (leave blank for a list of available targets):"
    @target = STDIN.gets.chomp

    while @target.empty?
      targets = `android list targets`
      puts targets
      puts "\nAndroid SDK platform you are targeting (e.g. android-8):"
      @target = STDIN.gets.chomp
    end
    
    # Define some paths
    @droidgap_dir = ROOT
    @droidgap_src_dir = File.join(@droidgap_dir, 'src')

    # instance_variables.each do |var|
    #   val = eval(var)
    #   puts "#{var} is #{val.class} and is equal to #{val.inspect}"
    # end
    # exit

    run
  end
  
  # runs the build script
  def run
    puts "\nHere we go!\n\n"
    make_output_directory
    build_jar
    create_android
    include_www
    generate_manifest
    copy_libs
    add_name_to_strings
    write_java
    puts "\nDone!\n\n"
    `open #{@output_dir}`
  end 
  
  # Creates an output directory
  def make_output_directory
    puts "Making output directory"
    # Double check that we don't clobber an existing dir
    if File.exists? @output_dir
      puts "\nSORRY! '#{ @output_dir }' directory already exists. Please try again.\n\n"
      exit
    end
    FileUtils.mkdir_p @output_dir
  end
  
  # Removes some files and recreates based on android_sdk_path 
  # then generates framework/phonegap.jar
  def build_jar
    puts "Building phonegap.jar"
    %w(build.properties local.properties phonegap.js phonegap.jar).each do |f|
      FileUtils.rm File.join(@droidgap_src_dir, f) if File.exists? File.join(@droidgap_src_dir, f)
    end
    open(File.join(@droidgap_src_dir, 'build.properties'), 'w') do |f|
      f.puts "target=#{ @target }"
    end 
    open(File.join(@droidgap_src_dir, 'local.properties'), 'w') do |f|
      f.puts "sdk.dir=#{ @android_sdk_path }"
    end 
    Dir.chdir(@droidgap_src_dir)
    `ant jar`
    Dir.chdir(@droidgap_dir)
  end

  # runs android create project
  def create_android
    puts "Creating Android project"
    `android create project -t #{ @target } -k #{ @pkg } -a #{ @name } -n #{ @name.gsub(' ','') } -p #{ @output_dir }`
  end
  
  # copies the project/www folder into tmp/android/www
  def include_www
    puts "Copying your web app directory"
    FileUtils.mkdir_p File.join(@output_dir, "assets", "www")
    FileUtils.cp_r File.join(@www, "."), File.join(@output_dir, "assets", "www")
  end

  # creates an AndroidManifest.xml for the project
  def generate_manifest
    puts "Creating AndroidManifest.xml"
    manifest = ""
    open(File.join(@droidgap_src_dir, "AndroidManifest.xml"), 'r') do |old|
      manifest = old.read
      manifest.gsub! 'android:versionCode="5"', 'android:versionCode="1"'
      manifest.gsub! 'package="com.phonegap"', "package=\"#{ @pkg }\""
      manifest.gsub! 'android:name=".StandAlone"', "android:name=\".#{ @name.gsub(' ','') }\""
      manifest.gsub! 'android:minSdkVersion="5"', 'android:minSdkVersion="2"'
    end
    open(File.join(@output_dir, "AndroidManifest.xml"), 'w') { |x| x.puts manifest }
  end

  # copies stuff from src directory into the project
  def copy_libs
    puts "Copying PhoneGap libs"
    framework_res_dir = File.join(@droidgap_src_dir, "res")
    app_res_dir = File.join(@output_dir, "res")
    # copies in the jar
    FileUtils.mkdir_p File.join(@output_dir, "libs")
    FileUtils.cp File.join(@droidgap_src_dir, "phonegap.jar"), File.join(@output_dir, "libs")
    # copies in the strings.xml
    FileUtils.mkdir_p File.join(app_res_dir, "values")
    FileUtils.cp File.join(framework_res_dir, "values","strings.xml"), File.join(app_res_dir, "values", "strings.xml")
    # drops in the layout files: main.xml and preview.xml
    FileUtils.mkdir_p File.join(app_res_dir, "layout")
    %w(main.xml preview.xml).each do |f|
      FileUtils.cp File.join(framework_res_dir, "layout", f), File.join(app_res_dir, "layout", f)
    end
    # icon file copy
    # if it is not in the www directory use the default one in the src dir
    if File.exists?(File.join(@www, "icon.png"))
      @icon = File.join(@www, "icon.png")
    else
      @icon = File.join(framework_res_dir, "drawable", "icon.png")
    end
    %w(drawable-hdpi drawable-ldpi drawable-mdpi).each do |e|
      FileUtils.mkdir_p(File.join(app_res_dir, e))
      FileUtils.cp(@icon, File.join(app_res_dir, e, "icon.png"))
    end
    # concat JS and put into www folder.
    js_dir = File.join(@droidgap_src_dir, "assets", "js")
    phonegapjs = IO.read(File.join(js_dir, 'phonegap.js.base'))
    Dir.new(js_dir).entries.each do |script|
      next if script[0].chr == "." or script == "phonegap.js.base"
      phonegapjs << IO.read(File.join(js_dir, script))
      phonegapjs << "\n\n"
    end
    File.open(File.join(@output_dir, "assets", "www", "phonegap.js"), 'w') {|f| f.write(phonegapjs) }
  end
  
  # puts app name in strings
  def add_name_to_strings
    puts "Creating strings.xml"
    x = "<?xml version=\"1.0\" encoding=\"utf-8\"?>
    <resources>
      <string name=\"app_name\">#{ @name }</string>
      <string name=\"go\">Snap</string>
    </resources>
    "
    open(File.join(@output_dir, "res", "values", "strings.xml"), 'w') do |f|
      f.puts x.gsub('    ','')
    end 
  end 

  # this is so fucking unholy yet oddly beautiful
  # not sure if I should thank Ruby or apologize for this abusive use of string interpolation
  def write_java
    puts "Creating java file"
    j = "
    package #{ @pkg };

    import android.app.Activity;
    import android.os.Bundle;
    import com.phonegap.*;

    public class #{ @name.gsub(' ','') } extends DroidGap
    {
        @Override
        public void onCreate(Bundle savedInstanceState)
        {
            super.onCreate(savedInstanceState);
            super.loadUrl(\"file:///android_asset/www/index.html\");
        }
    }
    "
    code_dir = File.join(@output_dir, "src", @pkg.gsub('.', File::SEPARATOR))
    FileUtils.mkdir_p(code_dir)
    open(File.join(code_dir, "#{ @name.gsub(' ','') }.java"),'w') { |f| f.puts j.gsub('    ','') }
  end
  #
end