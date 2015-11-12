# encoding: utf-8
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'
require 'pdf-reader'
require 'terminal-table/import'
require 'fuzzystringmatch'
require 'colorize'

# EANMAPFILEPATH = "C:/elguide/telling/ut/varer.dat"
EANMAPFILEPATH = "./varer.dat" #In this example, we have the varer.dat file in the
                               # same directory.

#
# TODO: Add verbosity options to the script.
#

#
# Parse a PDF and return an output file sorted by item number.
# Take an optional input file mapping EAN numbers to item descriptions.
# Take an optional file containing EAN numbers from item codes captured by the scanner.
# Create a table of EAN, and item description.
# Create a table of EAN, item description, and quantity.
# Check the master packing list for matching item descriptions. Check quantity field.
# If quantity needs to be updated, do so.
#

class OptparseExample

	#
	# Return a structure describing the options.
	#
	def self.parse(args)
		# The options specified on the command line will be collected in *options*.
		# We set default values here.
		options = OpenStruct.new
		options.packinglist = ""
		options.scanDataFilePath = [] #TODO: Be consistent with init values.
		options.outputSortedPackingList = false # Outputs a sorted packing list to console and a file.
		options.verbose = false
 
		opt_parser = OptionParser.new do |opts|
			opts.banner = "Usage: parser.rb [options]"

			opts.separator ""
			opts.separator "Specific options:"

			# Mandatory argument. TODO: Add the require switch
			opts.on("-p", "--packinglist <FILENAME>.pdf",
			"Specify the PDF file to parse before executing your script") do |name|
				options.packinglist << name
			end
			
			# Optional argument. 
			opts.on("-s", "--scanfile [SCANNERFILE1] [SCANNERFILE2] ", Array, 
      "Pass in scanner trans.dat files") do |name|
				puts "DEBUG: Name: #{name}"
				options.scanDataFilePath = name
			end
			
			# Optional argument. Boolean switch.
			opts.on("-o", "--outputsorted",
              "Output a sorted version of the packing list as a text file.") do |outputFlag|
				options.outputSortedPackingList = outputFlag
			end
			
			# Optional argument. Boolean switch.
			opts.on("-v", "--verbose",
              "Display verbose output") do |outputFlag|
				options.verbose = outputFlag
			end
			
			# Display a help message.
			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				exit
			end
		end

    opt_parser.parse!(args)
	options
	end  # parse()

end  # class OptparseExample

#
# Function definitions.
#

def makeReader(file)
	reader = nil
	reader = PDF::Reader.new(file)
	return reader
end

#
# Don't fill the list with blank lines.
# Better to just use a Ruby method that does the same thing.
# I think readlines may do it, but need to check.
#

def verifyEntry(entry)
	if entry == ""
		return nil
	else
		return entry
	end
end

#
# Returns a massive list of items, grouped by page on the packing list. Each item list
# is a newline separated string that needs further processing. Part of the
# PDF parsing code.
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
	end
	return sublist
end

#
# Stub. Add to the master list once a section has been parsed and hashed. 
# Returns nil. 
#

def addToMasterList(listOfHashedItems)
	return nil
end

#
# Stub. Checks the state of the master list.
# Returns nil.
#

def checkMasterList()
	return nil
end

#
# Helper function.
#

def convertNumField(strEntry)
	newEntry = strEntry.lstrip.chomp.split()
	return newEntry[0].to_i
end

#
# Alternative parser, to better get matches. Returns array of item properties.
# [itemNum, itemDesc, itemQuant]
# There's a bug whereby part of the order number can end up in the description field. 
# Need to check this. May be fixed.
#

def parseEntry(entry)
	splitEntry = []
		
	# Get the item number
	itemNum = /^(\w+)\s+/.match(entry.lstrip.chomp)
	splitEntry << itemNum[1]
	
  #
	# Old regex: itemDescription = /^\w+\s+(.+)\d{4,6}/.match(entry.lstrip.chomp)
  # Allowed the description field to capture the order number as well. This helps us avoid losing additional characters,
  # and the string matching still seems to work.
  #
  
	itemDescription = /^\w+\s+(.+\d{4,6})/.match(entry.lstrip.chomp)
  
	splitEntry << itemDescription[1]

	itemQuant = /\s{12,}(\d+).{,6}?$/.match(entry.lstrip.chomp)

	itemQuantity = convertNumField(itemQuant[1])
	splitEntry << itemQuantity
	
	return splitEntry
end

#
# Parse subsection
# Takes a subsection, breaks it into a list of substrings. 
# Returns array: item number, description, order, quantity 
# We can't easilt parse based on spaces. Sometimes fields run together. Get the spacing of an entry.
#

def parseEntryOld(entry)
	parsedEntry = {}
	itemQuantity = 0
	
	# We don't need the order info. Get rid of it.
	# Split on white space
	splitEntry = entry.chomp.lstrip.split(/\s{3,}/,4)
	#pp splitEntry.class
	#pp splitEntry
	
	# Convert the quantity field to a number
	if splitEntry[3]
		itemQuantity = convertNumField(splitEntry[3])
	else
		itemQuantity = 0
	end
	
	# Update the quantity field.
	splitEntry[3] = itemQuantity
	
	return splitEntry
end

#
# Stub. Turn a parsed subsection into a list of hash items.
# [{itemDescription => "DESCRIPTION", itemEAN => "EAN"}]
# Returns a list of hash items for the given subsection.
#

def convertToHash(parsedSubsection)
	listOfHashedItems = []
	
	return listOfHashedItems
end

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
end

#
# Create a master list. Format is below in entryHash. List of hash properties for each item.
# What I like about this approach is that the metadata of hash keys is clear. 
#
#

def createMasterList(reader)
	# Start by making a big list of item description strings.
	masterStringList = []
	masterHashList = []
	
	reader.pages.each do |page|
		section = splitIntoSections(page)
		masterStringList.concat(section)
	end
	
	masterStringList.each do |entry|
		# Here the entry is broken into list elements in its own array.
		parsedEntry = parseEntry(entry)
		entryHash = {:itemNum => parsedEntry[0],
					 :itemDesc => parsedEntry[1],
					 :itemQuant => parsedEntry[2],
					:scannedQuantity => nil,
					:scannedDescription => nil,
					:scannedEAN => nil,
					:scannedSerials => [],
					:confidence => nil,
					:descriptionFrequency => 0 # New field for detecting duplicates.
					}					
		masterHashList << entryHash
	end
	
	return masterHashList
end

#
# One use-case we have is that the packing lists and inventory list on the computer
# are not sorted the same. Nice to have them both share the same format. Makes it faster.
# Update: Need to verify how computer sorts items. Default doesn't seem to be by item 
# number.
#

def createSortedItemDescList(sortedList, masterHashList)
	descList = []
	
	masterHashList.each do |entry|
		itemNumber = entry[:itemNum]
		sortedList.each do |number|
			if number == itemNumber
				descList <<  [number,entry[:itemDesc],entry[:itemQuant]]
				break
			end
		end
	end

	return descList.sort
end

#
# As input, this takes a list of the form [["item number", "item description", item-quantity],]
# Returns a table that's fit for display on the screen or ASCII printer output.
# TODO: Play with padding to make this look better when printed on paper.
# TODO: Add column to tell if this has been scanned? Or do this later in a report.

def viewSortedItemDescList(descList)
	itemTotal = 0 # Total number of individual items in the order.
	
	displayTable = table do
		table.style = {:padding_left => 3, :padding_right => 3}
		self.headings = "Item Number", "Item Description", "Item quantity"
		
		descList.each do |entry|
			add_row [entry[0], entry[1], entry[2]]
			self.add_separator
			itemTotal += entry[2]
		end
		
		add_row [{value: "Total number of individual items on packing list", colspan: 2}, itemTotal]
		add_row [{value: "Total number of SKU entries on packing list:", colspan: 2}, descList.length]
	end
	puts displayTable
	return displayTable	
end

#
# As input, take a sorted item list and send it to a file.
# TODO: Allow us to specify a filename.
#

def outputFileSortedTable(tabularItemList)
	f = File.new("sortedPackingList.txt","w")
	f.write(tabularItemList)
end

#
# Returns a file handle.
#

def getFile(path)
	#See path format below
	#path = "C:/elguide/telling/ut/varer.dat"
	#puts Dir.pwd
	puts "Opening this file: #{path}"
	begin
		f = File.open(path,"r")
	rescue
		puts "File could not be opened at: #{path}"
	end	
	return f
end

#
# Returns a list of individual lines.
#

def processFile(fileHandle)
	puts "Processing file."
	
	begin
		lineArray = fileHandle.readlines
	rescue
		puts "Unable to open file."
	end
	
	return lineArray
		
end

#
# Transform the EAN data into a useful, hashed form.
#

def transformEanFile(itemIdDescList)
	#
	# Standard processing stuff. Chomp trailing spaces. Ignore blank lines.
	# The numeric codes are thirteen characters, then the rest is the item 
	# description.
	#

	hashedData = {}
	
	itemIdDescList.each do |entry|
		cleanEntry = entry.chomp
		
		#
		# Encoding hack. The data is tagged as UTF-8, but there are invalid byte sequences. I think
		# there's some Norwegian in here. I'll have to look up the encoding for that. 
		# This is a 'lossy' hack, in that we're converting to a different encoding than UTF-8 in order 
		# to force ruby to replace invalid characters. Then we convert back to UTF-8.
		# I'm willing to try this hack because the description matches will use 'fuzzy' matching
		# instead of regular expressions.
		#
	
		cleanEntry = cleanEntry.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8').lstrip.rstrip	
		#pp "DEBUG: Clean entry: #{cleanEntry}"
		begin
			itemID = cleanEntry.match(/^(\d{13})/)[1]
			#puts "DEBUG: Item ID: #{itemID}"
			#pp "Searching for item desc"
			begin
				itemDescription = cleanEntry.match(/^\d{13}(.+)/)[1]
			rescue Exception => ex
				puts ex
				puts "Can't parse description for EAN: #{itemID}"
			end
			hashedData[itemID] = itemDescription
			#puts "DEBUG: Item description: #{itemDescription}"
		rescue Exception => e
			pp e
			raise e
		end
	end
		
	return hashedData
end


#
# Transform the scanner data into a useful, hashed form.
# Return a list of the form: [{itemEAN => {itemQuant: , itemSerial: }}]
#

def transformScannerData(scanDataList)
	hashedData = {}

	#puts "DEBUG: in transform scanner data function."
	#puts "DEBUG: scanDataList: #{scanDataList}"
	#puts "DEBUG: scanDataList count: #{scanDataList.length}"
	scanDataList.each do |entry|
		serialNumbers = []
		cleanEntry = entry.chomp()
		
		itemEAN = cleanEntry.match(/(\w+)\s+/)[1] #TODO: Make this regex more strict.
		
		#
		# Assume serial numbers are longer than three digits.
		#
		
		itemQuantity = cleanEntry.match(/\s+(\w+)/)[1]   
		#puts "Item Quantity: #{itemQuantity}"
		#
		# Now we start to get more strict with the item quantity to
		# differentiate between item quantities and serial numbers.
		# Assumes any given order has no more than 999 of any given item.
		#
		
		if itemQuantity.length > 4 or itemQuantity !~ /\d{1,4}$/
			serialNumber = itemQuantity # If it´s a long number, assume a serial number.
			# Allow up to 9999 individual items for a given SKU in an order.
			serialNumbers << serialNumber # I think this could just be an int. Need to look at it more.
			itemQuantity = 1 # Items with serial numbers are always quantity = 1.
		end
		
    itemQuantity = itemQuantity.to_i
		#	
		# If item exists, do an update. This should work if we have duplicate EANs in a 
    # scan file.
		#

		if hashedData[itemEAN]
			#puts "!!!DEBUG: Found a duplicate EAN entry: #{itemEAN}"
			#puts "DEBUG: Updating item quantity."
			# Update the quantity field.
			
      hashedData[itemEAN][:itemQuant] += itemQuantity
			#puts "New quantity: #{hashedData[itemEAN][:itemQuant]}"  
      
      # Update the serial numbers field.
      if hashedData[itemEAN][:serialNumbers]
        hashedData[itemEAN][:serialNumbers] << serialNumbers[0]
      end
      #puts "DEBUG: hashedData Entry: #{itemEAN}:#{hashedData[itemEAN]}"
    
		else 
			#itemEAN # Otherwise create an entry.
			#puts "DEBUG: Creating an EAN entry."
			hashedData[itemEAN] = {itemQuant: itemQuantity, :serialNumbers => serialNumbers}
			#puts "DEBUG: hashedData Entry: #{itemEAN}:#{hashedData[itemEAN]}"
		end
	end
	
	#puts "DEBUG: number of key,value pairs in the hashed data: #{hashedData.length}"
	return hashedData
end

#
# This is where we combine the varer.dat file (EAN => Description) with the 
# output from the scanner (EAN => Quantity | serial number).
#

def generateDescriptionQuantityMap(hashedScannerData, hashedEanFile)
	descQuant = []
	
	# TODO: Quantities need to be fixed, showing as nil
	hashedScannerData.keys.each do |itemID|
		if hashedEanFile[itemID]
			descQuant << {itemEAN: itemID,
        itemDescription: hashedEanFile[itemID], 
				itemQuantity: hashedScannerData[itemID][:itemQuant],
				itemSerials: hashedScannerData[itemID][:serialNumbers]}
		end
	end
	
	return descQuant
end

#
# DEPRECATED.
# Warn if two items with different EANs share the same description.
# Tested. 
#

def checkForDuplicateDescriptions(descQuant)
	
	descriptions = {} # Hash of form Description => EAN
	duplicates = []
	
	descQuant.each do |item|
		# Only add to this hash if an item is not a duplicate.
		if descriptions[item[:itemDescription]]
			puts "WARNING: Item #{item[:itemDescription]} :: #{item[:itemEAN]} \
appears more than once but has different EANs. Check manually."
			duplicates << {item[:itemDescription] => item[:itemEAN]}
			
			#
			# Put both duplicate items in there.
			# We'll pull the item from the description hash now. It needs to be identified.
			# Anytime we get a duplicate description entry, the count of total entries
			# needs to be reduced by two.
			
			#
			# TODO: Return the quantity of the duplicates in addition to description and EAN.
			#
			
			duplicates << {item[:itemDescription] => descriptions[item[:itemDescription]]}
			
			#
			# Pull out the duplicate entry from the hash (okay to be destructive.)
			#
			
			puts "DEBUG: Deleting a duplicate entry. #{item[:itemDescription]} "
			descriptions.delete(item[:itemDescription])
		else
			descriptions[item[:itemDescription]] = item[:itemEAN]
		end
	end
	
	puts "DEBUG: WARN: Items with the same description but different EANs."
	duplicates.each do |dup|
		puts "WARN: Duplicate entry: #{dup}"
	end
	
	puts "DEBUG: Items with unique descriptions."
	descriptions.each do |description|
		puts "DEBUG: description hash entry: #{description}"
	end
		
	puts "DEBUG: number of items in unique description hash: #{descriptions.length}}"
	puts "DEBUG: Number of items in duplicates hash: #{duplicates.length}}"
	
	puts "DEBUG: Duplicates hash: #{duplicates}"
	return duplicates
end

#
# Bread and butter method to get all the matches between the packing list data and
# the scanned item data.
#

def getAllMatches(descQuant, masterHashList)

  # TODO: Make this cleaner by using a Ruby range. 
	#jaroTestValues = [0.99, 0.98, 0.97, 0.96, 0.95,0.94,0.93,0.92,0.91, 0.90,0.89, 0.88, 0.87,
#0.86,0.85, 0.84, 0.83, 0.82,0.81]
  
	#jaroTestValues = [0.99, 0.98, ]
	itemsMatched = []
	match = nil
	jarow = FuzzyStringMatch::JaroWinkler.create( :native )

	masterHashList.each do |expectedItem|
		jaroDistanceHash = {} # All results for a given entry in the master hash
		descQuant.each do |scannedItem|
			#jaroTestValues.each do |j|
			d = jarow.getDistance( scannedItem[:itemDescription], expectedItem[:itemDesc])
			jaroDistanceHash[d] = {scannedItem: scannedItem, expectedItem: expectedItem}
      #end	
		end

		#		
		# Sort keys in descending order. This puts the greatest Jarrow match value first in the array.
		#

		sortedKeys = jaroDistanceHash.keys.sort{|x,y| y <=> x}
    
		#		
		# Store the best match in the form {scannedItem: scannedItem, expectedItem: expectedItem}
		#

		bestMatch = jaroDistanceHash[sortedKeys[0]]
    
		#puts "DEBUG!!!! Best Match #{bestMatch}"
			
		#	
		# This gives us the best match in a set if the Jarrow distance is over 0.85
		# If match is less than that, we're looking at some dubious matches.
		#
    
    if sortedKeys[0] > 0.85
		
      # Update Master Hash List with: scannedQuantity, scannedDescription, confidence.
      # BUT: Only do this if this isn't an item with a duplicate description.

      expectedItem[:scannedQuantity] = bestMatch[:scannedItem][:itemQuantity]   
      expectedItem[:scannedDescription] = bestMatch[:scannedItem][:itemDescription]
      expectedItem[:scannedEAN] = bestMatch[:scannedItem][:itemEAN]
      expectedItem[:scannedSerials] = bestMatch[:scannedItem][:itemSerials]
      expectedItem[:confidence] = sortedKeys[0]
			
		end
	end
	# This list contains items matched.
	return masterHashList
end


def calculateTotalItemsScanned(combinedData)
	scannedTotal = 0

	combinedData.each do |entry|
		if entry[:scannedQuantity]
			scannedTotal += entry[:scannedQuantity]
		end 
	end
	
	return scannedTotal
end


#
# Helper to color code description frequencies.
# Any description that appears more than once on the packing list
# will require double checking the item quantity, since it's 
# a duplicate and will throw off the matching algorithm.
#

def descFreqColorCheck(entry)
	frequency = entry[:descriptionFrequency]
	
	if frequency > 1
		coloredEntry = frequency.to_s.red
	end
	
  return coloredEntry
end

#
# Helper to color code results based on match confidence.
#

def confidenceColorCheck(entry)
	confidence = entry[:confidence]

	if confidence == nil
		confidence = 0
	end

	if confidence >= 0.95
		coloredEntry = confidence.round(3).to_s.green
	elsif confidence >= 0.92 and confidence < 0.95
		coloredEntry = confidence.round(3).to_s.yellow
	elsif confidence > 0.80 and confidence < 0.92
		coloredEntry = confidence.round(3).to_s.magenta
	else
		coloredEntry = confidence.round(3).to_s.red
	end

	return coloredEntry
end

#
# Look for duplicate descriptions
#

def duplicateDescriptionUpdate(combinedData)
  #	
	# Items that have duplicate descriptions should be flagged for manual follow-up.
	# N^2 sized comparison. 
  #

	combinedData.each do |entry|
		combinedData.each do |record|
			if entry[:itemDesc] == record[:itemDesc]
				entry[:descriptionFrequency] += 1
			end
		end
    
    #
    # Items that have :descriptionFrequency > 1 need to unset the scanned
    # EAN and scanned quantities, since these could be wrong. We'll have
    # to match them manually for now.
    #
    
    if entry[:descriptionFrequency] > 1
      entry[:scannedQuantity] = nil
      entry[:scannedEAN] = nil
    end
	end
  
  return combinedData
end

#
# Data visualization. Table of items, including expected and scanned quantities.
#

def showCombinedData(combinedData)

	totalItemsScanned = calculateTotalItemsScanned(combinedData)
  combinedData = combinedData.sort_by {|k| k[:itemDesc].downcase}

  #combinedData = duplicateDescriptionUpdate(combinedData)
  
	displayTable = table do 
		self.headings = "SKU", "EAN", "Description", "Matched Description", "Expected_Quant", 
"Scanned_Quant", "Confidence", "Desc Freq"
	
    combinedData.each do |entry|
      colorCodedFrequency = descFreqColorCheck(entry)
		  colorCodedConfidence = confidenceColorCheck(entry)
		  add_row [ entry[:itemNum], entry[:scannedEAN],
	      entry[:itemDesc], entry[:scannedDescription], 
	      entry[:itemQuant], entry[:scannedQuantity], colorCodedConfidence, colorCodedFrequency ]
		  self.add_separator
	  end
		
    add_row [{value: "Total number of scanned items", colspan: 1}, totalItemsScanned]
  end
	
  # This is where we show the ASCII table of results.
	puts displayTable
	return displayTable, combinedData
end



def makeUniqMasterHash(masterHashList)
  
  #
  # Transform the existing list to make it unique with updated item quantities.
  # 
  
  uniqMasterHashList = []
  
  #
  # Make a blank list to hold uniq hash item numbers. We can sort these.
  #
  
  itemNumsUniqSorted = []
  
  #
  # Iterate through the hash items and create a list of item numbers.
  # Sort the list. This will be the item order. Make the list only hold
  # unique items.
  #
  
  masterHashList.each do |item|
    itemNumsUniqSorted << item[:itemNum]
  end
  itemNumsUniqSorted = itemNumsUniqSorted.uniq.sort()
  
  
  itemNumsUniqSorted.each do |num|
    
    # 
    # This is a list of all items in the masterHashList that match a given uniq item number.
    #
    
    occurences = masterHashList.find_all {|m| m[:itemNum] == num} 
    
    #
    # Start our count from zero until we tell it otherwise.
    #
    
    itemTotal = 0
    
    #
    # Update total number of items for a given SKU. 
    #
    
    occurences.each do |instance|
      itemTotal += instance[:itemQuant]
    end
    
    #
    # Hackish: Since all the instances in occurences are the same type of item
    # (with the same article number,) then just take the first occurence in
    # the list and change the quantity to the total number of items counted. 
    #
    occurences[0][:itemQuant] = itemTotal
    uniqMasterHashList << occurences[0]
  end
      
  uniqMasterHashList.each do |c|
    #puts "DEBUG: Unique items: #{c[:itemNum]}::#{c[:itemQuant]}"
  end

  total = 0
  totalItemsExpected = uniqMasterHashList.each do |i|
    total += i[:itemQuant]
  end
  
  puts "INFO: Total unique items expected after consolidating duplicate SKUs: #{total}"
  puts "INFO: Total unique SKUs expected after consolidation: #{uniqMasterHashList.length} "
  #sortedList = uniqMasterHashList.sort_by {|k| k[:itemDescription]}
  #return sortedList
  return uniqMasterHashList 
 
end


#
# Look for results that appear in the scanner data but weren't matched.
# 
# Remember: descQuant << {itemEAN: itemID,
#						itemDescription: hashedEanFile[itemID], 
#						itemQuantity: hashedScannerData[itemID][:itemQuant],
#						itemSerials: hashedScannerData[itemID][:serialNumbers]}
#
# TODO, move this higher up where it belongs.
#

def findUnmatchedResults(descQuant, uniqHashList)
  
  matched = []
  notMatched = []
  sortedNotmatched = []

  matched = uniqHashList.find_all {|i| i[:scannedEAN] != nil}
  descQuant.each do |scanned|
    if matched.find { |i| i[:scannedEAN] == scanned[:itemEAN] }
    else
      notMatched << scanned
    end
  end

  sorted = notMatched.sort_by {|k| k[:itemDescription].downcase} 
  
  puts "WARN: The following items were scanned but could not be \
reliably matched against the packing list using description strings."
  puts "***"
  
  
	displayTable = table do 
		self.headings = "Description", "Quantity", "EAN"
	
    sorted.each do |entry|
		  add_row [ entry[:itemDescription], entry[:itemQuantity],
	      entry[:itemEAN] ]
		  self.add_separator
    end
  end
  
  puts displayTable
end

#
# Main program execution
#

scanDataFileHandle = nil
scanDataList = nil
hashedScannerData = {}
eanFileHandle = nil
eanMapList = nil
hashedEanFile = {}
descQuant = [] # EANs, descriptions, and scanned quantities. Used when we
			   # match items in the packing list.
tabularItemList = []
options = OptparseExample.parse(ARGV)

#
# Maybe we don't make PDF processing a required option.
#

if (options.packinglist != "")
	puts "Processing PDF packing list."
	begin
		reader = makeReader(options.packinglist)
		if reader
			puts "Created reader object from packing list."
		end
	rescue
		puts "Unable to process input packing list. Check file name and path."
		puts "Exiting."
		exit
	end
	
	masterHashList = createMasterList(reader)
	sortedItemNumList = generateSortedList(masterHashList)
	nestedItemList = createSortedItemDescList(sortedItemNumList, masterHashList)
	tabularItemList = viewSortedItemDescList(nestedItemList)
		
	if (options.outputSortedPackingList)
		outputFileSortedTable(tabularItemList)
	end
end

#
# Hand scanner enabling code. For automating the counting process.
#

if (options.scanDataFilePath != [])
	begin
		puts "INFO: Processing EAN mapping file." # This is varer.dat
		masterEanMapList = [] # Consolidate all the lines from all the EAN files into a single array.
    options.scanDataFilePath.each do |file|
      eanFileHandle = getFile(EANMAPFILEPATH)	
		  #puts "DEBUG: Got EAN File handle: #{eanFileHandle}"
		  eanMapList = processFile(eanFileHandle)
      masterEanMapList.concat(eanMapList)
    end	
		  #puts "DEBUG: Printing first line from eanMapList #{eanMapList[0]}"
		  hashedEanFile = transformEanFile(masterEanMapList)
    
	rescue Exception => e
		puts "Unable to process EAN mapping file at #{EANMAPFILEPATH}"
		raise e
		puts e
		exit
	end

	begin
		puts "INFO: Processing scan data file."
		masterScanDataList = []
    options.scanDataFilePath.each do |file|
      scanDataFileHandle = getFile(file)
		  scanDataList = processFile(scanDataFileHandle)
      masterScanDataList.concat(scanDataList)
    end
		
		# DEBUG
		#puts "DEBUG: scanDataList"
		#puts "DEBUG: Scan data list length: #{scanDataList.length}"
		
		hashedScannerData = transformScannerData(masterScanDataList)
	rescue
		puts "ERROR: Unable to process scan data file."
	end
	
	if options.verbose 
		puts "INFO: Hashed Scanner Data."
		hashedScannerData.each do |key,values|
			puts "INFO: Item ID: #{key} => Item Info: #{values}"
			
		end
		puts "INFO: Number of products: #{hashedScannerData.keys.length}"
	end
	
	#
	# TODO: Add support to consolidate multiple scan files.
	#
	
	#
	# This list is from the scanner data.
	# We're matching the EAN descriptions with the scanner data using EANs as keys.
	#

	descQuant = generateDescriptionQuantityMap(hashedScannerData, hashedEanFile)

	#
	# Let's go through the list and immediately warn if items with different EANs have the same
	# item description. We'll save this output as well.
	# TODO: Find a good way to display this information in the reports.
	#
	
	if options.verbose
		puts "INFO: Hashed descriptionQuantity map."
		descQuant.each do |entry|
			puts "INFO: Item scanned: #{entry}"
		end
		puts "INFO: Length of desc quantity list: #{descQuant.length}"
	end

  #
  # Need to make the master hash list sorted by SKU as well as containing only
  # unique items.
  #

  uniqHashList = makeUniqMasterHash(masterHashList)

	#	
	# Match scanned output with packing list data to make a list of items received.
	# Be prepared for there to be items with different EANs but the same description.
	#

	combinedData = getAllMatches(descQuant, uniqHashList)
  
  #
  # Transform the combined scanner and packing list data, adding in values for 
  # description frequency. If we find a value for description frequency > 1,
  # clear the scanned EAN as well as scanned quantities. This allows us to better
  # flag a dubious result and prevents us from displaying false EAN data for items
  # that match on a duplicate description.
  #
  
  combinedData = duplicateDescriptionUpdate(combinedData)
	
	# Take the combined data and display it in a nice table.

	showCombinedData(combinedData)

	#Show items scanned but not matched.For every item in the scanner output map,
	# check the EAN. Do a find in the updated Master Hash list by the EAN for
	# every item. If no result, then save this result and print it on a newline.	
  findUnmatchedResults(descQuant, uniqHashList)

end


# C:\Users\user\Desktop\Code\ruby>ruby parser.rb -p packing_note1_20151012_202409.pdf -s trans1.dat -v

