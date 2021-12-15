local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerData = ServerScriptService.Data
local QuestionData = require(ServerData.QuestionData)

local RepServices = ReplicatedStorage.Services
local TimerService = require(RepServices.TimerService)

local Utility = ReplicatedStorage.Utility
local Postie = require(Utility.Postie)
local Shared = require(Utility.Shared)

local Remotes = ReplicatedStorage.Remotes

local TriviaRemote = Instance.new("RemoteEvent")
TriviaRemote.Name = "TriviaRemote"
TriviaRemote.Parent = Remotes

local TriviaService = {}

local function getAverage(list)
	local sum = 0
	
	for i,v in ipairs(list) do
		sum += v
	end
	
	return sum / #list
end

local function convertQuestionsToSend(questions)
	local convertedQuestions = {}

	for _,info in ipairs(questions) do
		local converted = {
			q = info.question,
			a = TriviaService:GetAnswers(info),
			t = info.questionType,
			id = info.id
		}
		
		if converted.t == "image" then
			converted.i = info.image
		end

		table.insert(convertedQuestions, converted)
	end

	return convertedQuestions
end

local function checkQuestionAnswer(id, choice)
	local questionData = QuestionData[id]
	if choice == questionData.correct then
		return true
	end

	return false, questionData.correct
end

function TriviaService.Init()
	for id,q in ipairs(QuestionData) do
		q.id = id
		q.questionType = q.questionType or "text"
		
		for a,v in pairs(q.answers) do
			if v then
				q.correct = a
				break
			end
		end
	end
end

function TriviaService:StartRound(player, amount, seed)
	local questions = self:SelectQuestions(amount, seed)
	local convertedQuestions = convertQuestionsToSend(questions)
	
	local pointScore = 0
	local roundStats = {
		correct = 0,
		answerTimes = {}
	}
	
	local valid, response = Postie.InvokeClient("StartRound", player, Shared.CLIENT_WAIT_TIME, {numberQuestions = #convertedQuestions})
	
	if valid and response then
		if response.status then
			
			for i, info in ipairs(convertedQuestions) do
				local startTime = Shared.GetTime()
				
				local valid, response = Postie.InvokeClient("AskQuestion", player, Shared.DEFAULT_QUESTION_TIME + 5, {question = info, startTime = Shared.GetTime()})
				if valid and response then -- They gave an answer
					local answerTime = response.answerTime - (startTime + response.ping)
					table.insert(roundStats.answerTimes, answerTime)
					
					local rewardedPoints = math.clamp(math.floor((Shared.DEFAULT_QUESTION_TIME+1 - answerTime) / 2 + 0.5), 0, Shared.DEFAULT_QUESTION_TIME / 2)
					
					local choiceWasCorrect, correctAnswer = checkQuestionAnswer(info.id, response.choice)
					
					if choiceWasCorrect then
						roundStats.correct += 1
						rewardedPoints += 25
					end
					
					pointScore += rewardedPoints
				
					local valid, response = Postie.InvokeClient("ReturnAnswer", player, Shared.CLIENT_WAIT_TIME, {status = choiceWasCorrect, points = rewardedPoints, correctAnswer = correctAnswer, answerTime = answerTime, lastQuestion = (i == #convertedQuestions)})
					
					if not valid or not response then
						break
					end
				else -- No answer was given in time limit
					local choiceWasCorrect, correctAnswer = checkQuestionAnswer(info.id, "")
					local valid, response = Postie.InvokeClient("ReturnAnswer", player, Shared.CLIENT_WAIT_TIME, {status = false, correctAnswer = correctAnswer})
					
					if not valid or not response then
						break
					end
				end
			end
			
			local valid, response = Postie.InvokeClient("EndQuiz", player, Shared.CLIENT_WAIT_TIME, {
				playerStats = {
					correct = roundStats.correct,
					averageAnswerTime = getAverage(roundStats.answerTimes)
				}
			})
		end
	end
end

function TriviaService:SelectQuestions(amount, seed)
	local random
	if seed then
		random = Random.new(seed)
	else
		random = Random.new()
	end

	local questions = {}
	local duplicate = {}

	while #questions < amount do
		local questionId = random:NextInteger(1, #QuestionData)
		if not duplicate[tostring(questionId)] then
			duplicate[tostring(questionId)] = true
			table.insert(questions, QuestionData[questionId])
		end

		task.wait()
	end

	return questions
end

function TriviaService:GetAnswers(question)
	local answers = {}

	for answer, value in pairs(question.answers) do
		if value then
			table.insert(answers, {answer = answer, sortValue = 1})
		else
			table.insert(answers, {answer = answer, sortValue = math.random(2,101)})
		end
	end

	table.sort(answers, function(a,b) return a.sortValue < b.sortValue end)

	if #answers > 4 then
		for i = 1,#answers-4 do
			table.remove(answers, 5)
		end
	end

	for _,info in ipairs(answers) do
		info.sortValue = math.random(1,100)
	end

	table.sort(answers, function(a,b) return a.sortValue < b.sortValue end)

	local converted = {}

	for _,info in ipairs(answers) do
		table.insert(converted, info.answer)
	end

	return converted
end

--------------------------------------------------------------

return TriviaService
