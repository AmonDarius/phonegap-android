#
# Run
# ---
#
# A handy machine that does the following:
#
# - packages www to a valid android project in tmp/android
# - builds tmp/android project into an apk
# - installs apk onto first device found
# - attaches a logger to catch output from console.log statements
#
class Run
  # if no path is supplied uses current directory for project
  def initialize(path)
    @pkg = Package.new(path)    
    @apk = File.join(@pkg.path, "bin", "#{ @pkg.name }-debug.apk")

    build
    install
  end
  
  def first
    `adb devices`.split("\n").pop().gsub('device','')
  end
  
  # creates tmp/android/bin/project.apk
  def build
    `cd #{ @pkg.path }; ant debug`
  end 
  
  # installs apk to first device found, if none is found the first avd is launched
  def install
    `adb -s #{ first } install -r #{ @apk } 2>&1 > /dev/null`
  end
  #
end