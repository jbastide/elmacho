require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'
require 'pdf-reader'

#
# TODO: Add verbosity options to the script.
#
# Specify an input file and options
#

class OptparseExample

  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.file = []
    options.inplace = false
    options.encoding = "utf8"
    options.transfer_type = :auto
    options.verbose = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: parser.rb [options]"

      opts.separator ""
      opts.separator "Specific options:"

      # Mandatory argument.
      opts.on("-r", "--require FILE.pdf",
              "Specify the PDF file to parse before executing your script") do |name|
        options.file << name
      end
    end

    opt_parser.parse!(args)
    options
  end  # parse()

end  # class OptparseExample

options = OptparseExample.parse(ARGV)
#pp options
#pp ARGV


#
# DEBUG
#
FILENAME = "packing_note1_20150930_184047.pdf"

def makeReader(file)
	reader = nil
	reader = PDF::Reader.new(file)
	return reader
end

#
# Don't fill the list with blank lines.
#

def verifyEntry(entry)
	if entry == ""
		#puts "Blank Line. Not pushing to list."
		return nil
	else
		return entry
	end
end


#
# Returns a massive list of items, grouped by page on the packing list. Each item list
# is a newline separated string that needs further processing.
#

def splitIntoSections(page)	
	sublist = []

	#
	# Break this on newlines. A lot easier to parse.
	# Returns a list.
	#
	
	splitPage = page.text.split(/\n/)	
	
	#
	# If you find the 'Artikel' line, set a boolean to gather matches until 
	# you get to the next line which is only a newline.
	#
	
	match = false
	
	splitPage.each do |entry|
		
		#
		# If we have two consecutive newlines, we are done.
		#

		#if (entry == "")
		#	newlineCounter += 1
		#	#puts "DEBUG: Found NEWLINE on own line."
		#	#Newline count: #{newlineCounter.to_s}"
		
		if entry =~ (/Artikel/)
			
			#
			# Go to the next entry after the descriptor field and save each line
			# until you get to the end of the data field.
			#
			
			match = true
			
			# Reset the newline counter in case of spaces between Artikel and the first item.
			#newlineCounter = 0
			next
		elsif entry =~ /Last/ or entry =~ /Utskriftstid/
			match = false # Use that keyword match as the separator
		elsif match == true # Only after all the checks are true do we push the data to the list.
			verifiedEntry = verifyEntry(entry)
			if verifiedEntry != nil
				sublist << verifiedEntry
			end
		end
		
		#if (newlineCounter == 2)
		#	#puts "DEBUG: Found subsection boundary. Resetting newlineCounter"
		#	match = false
		#	newlineCounter = 0
		#end
		
		#
		#
		#
		#if match == true
		#	sublist.append(entry) 
	end
	#pp "DEBUG: Printing sublist"
	#pp sublist
	#pp "DEBUG: Number of SKUs on page."
	#pp sublist.length
	
	# DEBUG
	#if page.number == 2
	#	puts page.text
	#end
	return sublist
end

#
# Add to the master list once a section has been parsed and hashed. 
# Returns nil. (Change this, we should try except here.)
#

def addToMasterList(listOfHashedItems)

	return nil
end

#
# Checks the state of the master list.
# Returns nil.
#

def checkMasterList()

	return nil
end


def convertNumField(strEntry)
	newEntry = strEntry.lstrip.chomp.split()
	return newEntry[0].to_i
end

#
# Parse subsection
# Takes a subsection, breaks it into a list of substrings. 
# Returns nested array: item number, description, order, quantity 
#

def parseEntry(entry)
	parsedEntry = {}
	itemQuantity = 0
	
	# Split on white space
	splitEntry = entry.chomp.lstrip.split(/\s{3,}/,4)
	
	# Convert the quantity field to a number
	if splitEntry[3]
		itemQuantity = convertNumField(splitEntry[3])
	else
		itemQuantity = 1
	end
	
	# Update the quantity field.
	splitEntry[3] = itemQuantity
	
	return splitEntry
end

#
# Turn a parsed subsection into a list of hash items.
# [{itemDescription => "DESCRIPTION", itemEAN => "EAN"}]
# Returns a list of hash items for the given subsection.
#

def convertToHash(parsedSubsection)
	listOfHashedItems = []
	
	return listOfHashedItems
end

# Create a reader object
reader = makeReader(FILENAME)

#
# Create a sorted list of Item numbers and descriptions based on the master list.
#

def generateSortedList(masterHashList)
	# Create list of item numbers'
	itemNumbers = []
	
	masterHashList.each do |item|
		itemNumbers << item[:itemNum] 
	end
	
	sortedItemNumbers = itemNumbers.sort
	return sortedItemNumbers
	#pp sortedItemNumbers
	#exit
end

# create a master list

def createMasterList(reader)
	# Start by making a big list of item description strings.
	masterStringList = []
	masterHashList = []
	
	reader.pages.each do |page|
		puts "DEBUG: Splitting into sections. PAGE: #{page.number}"
		section = splitIntoSections(page)
		masterStringList.concat(section)
	end
	
	masterStringList.each do |entry|
		# Here the entry is broken into list elements in its own array.
		parsedEntry = parseEntry(entry)
		entryHash = {:itemNum => parsedEntry[0],
					 :itemDesc => parsedEntry[1],
					 :itemOrder => parsedEntry[2],
					 :itemQuant => parsedEntry[3]
					}					
		masterHashList << entryHash
	end
	
	return masterHashList

end

def createSortedItemDescList(sortedList, masterHashList)
	
	descList = []
	
	masterHashList.each do |entry|
		itemNumber = entry[:itemNum]
		sortedList.each do |number|
			if number == itemNumber
				descList <<  [number,entry[:itemDesc]]
				break
			end
		end
	end
	
	#numberDescList = [{itemNumber => description}]
	numberDescList = []
	
	#pp sortedList.length
	#pp masterHashList.length
	
	sortedList.each do |itemNumber|
		# If the itemNum of a hash entry matches, then store both the 
		# item number and description.
		masterHashList.each do |entry|
			#pp entry[:itemNum]
			if entry[:itemNum] == itemNumber
				#puts "MATCH"
			
				#numberDescList << {itemNumber => entry[:itemDesc]}
			end
		end
	end
	pp descList.length
	pp masterHashList.length
	return descList
	#pp "NUMBER ITEMS:"
	#pp numberDescList.length
end
masterHashList = createMasterList(reader)

sortedItemNumList = generateSortedList(masterHashList)

createSortedItemDescList(sortedItemNumList, masterHashList)
