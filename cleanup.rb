# find duplicate files then move and delete them
# author: mos

require 'json'
require 'fileutils'
require 'date'

#puts Dir["D:/Users/moabd/Documents/**"]
#puts Dir.chdir('D:/')
#puts Dir.glob('**/*').select {|f| File.directory? f}
#puts Dir.glob('**').select {|f| File.file? f}.class
#File.mtime("testfile")

$files = []
$errors = []
$duplicates = []

def findAllFiles(directory = 'D:/')
  # find all folders in the current directory
  folders = []
  begin
    Dir.chdir(directory)

    Dir.glob('*').select do |f|
      if File.directory?(f)
        folders.append("#{directory}#{f}/")
      else
        begin
        $files.append([f, "#{directory}", File.mtime(f), File.size(f)]) if File.file?(f)
        rescue => error
          puts "#{error}  - #{f} in #{directory}"
          $errors.append("#{error}  - #{f} in #{directory}")
        end
      end
    end
    # loop through each sub folder gathering files and folders
    folders.each { |folder| findAllFiles(folder) }
  rescue => error
    puts "#{error}  - in #{directory}"
    $errors.append("#{error}  - in #{directory}")
  end
end

def multiDrives(drives = ['D:/', 'C:/'])
  drives.each { |drive|
    puts "Starting looking through #{drive}"
    findAllFiles(drive)
    puts "Done looking through #{drive}"
  }
end

def sortFiles
  puts "Sorting..."
  $files = $files.sort_by{|a| a[0]}
  puts "Done sorting"
end

def findDuplicates
  puts "Finding duplicates"
  # loop through files
  i = 0
  numFiles = $files.length
  repeats = []
  while i < numFiles
    if (i < numFiles - 1 && $files[i][0].to_s.eql?($files[i+1][0]).to_s) || (i > 0 && $files[i][0].to_s.eql?($files[i-1][0]).to_s)
      #puts "#{$files[i][0]} #{$files[i][1]}"
      repeats.append($files[i])
    elsif repeats.length > 0
      repeats.sort_by{|a| Date.strptime(a[2].to_s, "%Y-%m-%d %H:%M:%S %z") }.reverse
      # "2008-06-09 22:02:22 -0600"
      $duplicates.append(repeats)
      repeats = []
    end
    i += 1
  end
  # 0 file name  1 directory  2 date  3 bytes
  # $duplicates.each { |duplicate|
  #  duplicateString = "#{duplicate[0][0]}"
  #  duplicate.each { |file| duplicateString += " #{file[2]}"}
  #  #puts duplicateString
  #}
  puts "Found duplicates of #{$duplicates.length} files"
end

def writeToFile
  puts "Writing to files"
  # errors
  i = 0
  arrString = "[\n"
  while i < $errors.length - 1
    arrString += "#{JSON.generate($errors[i])},\n"
    i += 1
  end
  arrString += "#{JSON.generate($errors[i])}\n]"
  File.open("C:/duplicates/errors.txt", 'w') { |file| file.write(arrString) }

  # duplicates
  i = 0
  arrString = "[\n"
  while i < $duplicates.length - 1
    arrString += "#{JSON.generate($duplicates[i])},\n"
    i += 1
  end
  arrString += "#{JSON.generate($duplicates[i])}\n]"
  File.open("C:/duplicates/duplicates.txt", 'w') { |file| file.write(arrString) }

  puts "Done writing to files"
end

def fileToArray
  puts "Reading duplicates from file"
  file = File.open("C:/duplicates/duplicates.txt")
  $duplicates = JSON.parse(file.read)
  puts "Duplicates read"
end

def deleteFiles
  puts "Moving duplicate files"
  return if $duplicates.empty? || $duplicates.nil? || $duplicates.length <= 0
  $duplicates.each { |files|
    path = "C:/duplicates/#{files[0][0]}/"
    FileUtils.mkdir_p path
    i = 1
    filesString = "#{files[0][0]}\n#{files[0][1]}\n#{files[0][2]}\n#{files[0][3]} bytes\n\n"
    while i < files.length
      filesString += "#{files[i][0]}\n#{files[i][1]}\n#{files[i][2]}\n#{files[i][3]} bytes\n\n"
      #FileUtils.mv("#{files[i][1]}#{files[i][0]}", "#{path}#{i}#{files[i][0]}")
      i += 1
    end
    File.open("#{path}/#{files[0][0]}.txt", "w") {|f| f.write(filesString) }
  }
  puts "Done moving files"
end

findAllFiles('D:/Users/moabd/Documents/')
sortFiles()
findDuplicates()
writeToFile()
#fileToArray()
deleteFiles()

#puts $files