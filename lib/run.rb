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
    @apk = File.join(@pkg.path, "bin", "#{ @pkg.name.gsub(' ','') }-debug.apk")

    build
    install
  end
  
  # returns the first device attached
  def first_device
    fd = `adb devices`.split("\n").pop()
    if fd == 'List of devices attached '
      nil
    else
      fd.gsub('device','')
    end 
  end
  
  # returns the first emulator
  def first_avd
    `android list avd | grep "Name: "`.gsub('Name: ','')
  end
  
  # creates tmp/android/bin/project.apk
  def build
    `cd #{ @pkg.path }; ant debug`
  end 
  
  # installs apk to first device or emulator found
  def install
    if first_device.nil?
      `emulator -avd #{ first_avd }; cd #{ @pkg.path }; ant install 2>&1 > /dev/null`
    else
      `adb -s #{ first_device } install -r #{ @apk } 2>&1 > /dev/null`
    end 
  end
  #
end