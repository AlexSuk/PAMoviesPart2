class MovieData 
	attr_reader :testing_data, :training_data
	def initialize(training, test = nil)
		if test != nil
			testing_file = test
			@testing_data = load_data_for_test(testing_file)
		end
		#if the training file exists, open
		if training != nil
			train_file = open(training)
			@training_data = load_data(train_file)
		end
	end

	def load_data(file)
		user_movie = Hash.new
		#going through each line
		file.each_line do |line|
			#turning the line into array elements and then making a new array that contains
			#string numerals in integer form
			read_line_array = line.split
			integer_value_line = read_line_array.map {|x|x.to_i}
			#if the hash already has the user id, than just add the movie and rating (as a key-value pair) to the user id's value, otherwise, create and new key for the user id and make a new hash
			if user_movie.has_key?(integer_value_line[0]) 
				user_movie[integer_value_line[0]][integer_value_line[1]] = integer_value_line[2]
			else 
				user_movie[integer_value_line[0]] = Hash.new
				user_movie[integer_value_line[0]][integer_value_line[1]] = integer_value_line[2]
			end

		end
		return user_movie
	end
	#the test file will only be used for predictions. Thus, the data needs to be stored accordingly in the format [u,m,r,p] to be more useful in the future
	def load_data_for_test(file_name)
		file = open(file_name)		
		predictions = Array.new
	 	file.each_line do |line|
	 		line_into_array = line.split
	 		integer_value = line_into_array.map {|x|x.to_i}
	 		predictions << integer_value
	 	end
	 	return predictions
	end

	#will return all the movies that the user watched 
	def movies(user)
		return training_data[user].keys
	end
	
	def rating(user, movie)
		all_movies = movies(user) #seeing if the user watched the movie by looking through the array of keys from the movie_id => movie_rating hash 
		if all_movies.include?(movie)
			return training_data[user][movie] 
		else
			return 0
		end
	end

	def viewers(movie)
		viewers = Array.new
		usr_ids = training_data.keys 
		usr_ids.each do |x|
			if training_data[x].keys.include?(movie)
				viewers << x
			end
		end
		return viewers
	end

	#returns floating point between 1 and 5 as an estimate on what a user would rate a movie
	def predict(user, movie)
		people_watched_movie = viewers(movie)
		user_counter = 0
		similar = Array.new
		while(user_counter < people_watched_movie.size) 
			if(people_watched_movie[user_counter] == user) 
				user_counter += 1 #don't do anything because I do not want to compare a user to himself
			else
				similar << similarity(user, people_watched_movie[user_counter]) #get the similarity results 
				user_counter += 1
			end
		end
		if similar.size == 0
			return 1
		else
			#due to large data set, to run predict on all 20,000 lines of u1.test, it takes about 7 minutes
			most_similar_user = people_watched_movie[similar.index(similar.max)]  #finding the most similar user SOLELY based on number of similar movies they watched
			return (rating(most_similar_user, movie) + user_mean(user)) / 2   #finding the average rating that the user usually gives, then averaging it together with the rating of the most similar use who also watched ths current movie in question
		end
	end
	
	def similarity(user1, user2)
		in_common = movies(user1) & movies(user2) #contains the commons elements of both movies that they watched
		return in_common.size
	end

	def user_mean(user)
		total_rating_average = 0.0
		count = 0
		user_all_movies = movies(user)
		user_all_movies.each do |x|
			total_rating_average += rating(user, x)
			count += 1
		end
		return total_rating_average/count
	end

	#because of the method t.to_a, will be sorting the array the predictions into [u,m,r,p] form
	 def run_test(k = nil)
	 	k_counter = 0
	 	new_array_k = Array.new
	 	if k == nil
		 	testing_data.each_index {|inside_hash|
		 		testing_data[inside_hash][3] = predict(testing_data[inside_hash][0], testing_data[inside_hash][1])  #have to add in the predictions into the testing_data set
		 	}
		 	return MovieTest.new(testing_data)
		 else 
		 	while(k_counter < k )
		 		testing_data[k_counter][3] = predict(testing_data[k_counter][0], testing_data[k_counter][1])
		 		new_array_k << testing_data[k_counter]
		 		k_counter += 1
		 	end
		 	
		 	return MovieTest.new(new_array_k)
		end
	 	
	 end
end

class MovieTest
	attr_reader :predictions

	def initialize(predictions)
		@predictions = predictions
	end
	def mean 
		#average = the total prediction error  / the amount of predictions 
		total_prediction_error = 0.0
		amount_of_predictions = 0;
		predictions.each do |inside_array|
			total_prediction_error += (inside_array[3] - inside_array[2]).abs 
			amount_of_predictions += 1
		end
		return total_prediction_error / amount_of_predictions
	end

	def stddev 
		mean_value = mean
		total_variance = 0.0
		predictions.each do |inside_array|
			total_variance += (inside_array[3] - mean_value)**2  #for each number: subtract the prediction from the Mean and square the result.
		end
		return Math.sqrt(total_variance/predictions.size) #take square root of the  mean of those squared differences.
	end

	def rms
		#take the mean squared of the error and then square root it
		total_error = 0.0
		predictions.each do |inside_array|
			#for each number: subtract the Mean and square the result.
			total_error+= (inside_array[3] - inside_array[2])**2     #(prediction - actual) ^ 2
		end
		return Math.sqrt(total_error/predictions.size)
	end

	def to_a
		return predictions
	end

end

z = MovieData.new('u1.base', 'u1.test')
tests = z.run_test(39)

puts tests.mean
puts tests.stddev
puts tests.rms


