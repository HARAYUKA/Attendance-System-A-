# coding: utf-8

User.create!(name: "管理者",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true)
             
User.create!(name: "上長A",
             email: "sample1@email.com",
             password: "password",
             password_confirmation: "password",
             superior: true,
             employee_number: "101")             

User.create!(name: "上長B",
             email: "sample2@email.com",
             password: "password",
             password_confirmation: "password",
             superior: true,
             employee_number: "102")
             
3.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password,
               employee_number: "#{n+103}")
end