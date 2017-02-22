FactoryGirl.define do
  factory :key, aliases: [:rsa_key_2048] do
    title
    key do
      'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFf6RYK3qu/RKF/3ndJmL5xgMLp3O96x8lTay+QGZ0+9FnnAXMdUqBq/ZU6d/gyMB4IaW3nHzM1w049++yAB6UPCzMB8Uo27K5/jyZCtj7Vm9PFNjF/8am1kp46c/SeYicQgQaSBdzIW3UDEa1Ef68qroOlvpi9PYZ/tA7M0YP0K5PXX+E36zaIRnJVMPT3f2k+GnrxtjafZrwFdpOP/Fol5BQLBgcsyiU+LM1SuaCrzd8c9vyaTA1CxrkxaZh+buAi0PmdDtaDrHd42gqZkXCKavyvgM5o2CkQ5LJHCgzpXy05qNFzmThBSkb+XtoxbyagBiGbVZtSVow6Xa7qewz= dummy@gitlab.com'
    end

    factory :deploy_key, class: 'DeployKey' do
      key do
        'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFf6RYK3qu/RKF/3ndJmL5xgMLp3O96x8lTay+QGZ0+9FnnAXMdUqBq/ZU6d/gyMB4IaW3nHzM1w049++yAB6UPCzMB8Uo27K5/jyZCtj7Vm9PFNjF/8am1kp46c/SeYicQgQaSBdzIW3UDEa1Ef68qroOlvpi9PYZ/tA7M0YP0K5PXX+E36zaIRnJVMPT3f2k+GnrxtjafZrwFdpOP/Fol5BQLBgcsyiU+LM1SuaCrzd8c9vyaTA1CxrkxaZh+buAi0PmdDtaDrHd42gqZkXCKavyvgM5o2CkQ5LJHCgzpXy05qNFzmThBSkb+XtoxbyagBiGbVZtSVow6Xa7qewz'
      end
    end

    factory :personal_key do
      user
    end

    factory :another_key do
      key do
        'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmTillFzNTrrGgwaCKaSj+QCz81E6jBc/s9av0+3b1Hwfxgkqjl4nAK/OD2NjgyrONDTDfR8cRN4eAAy6nY8GLkOyYBDyuc5nTMqs5z3yVuTwf3koGm/YQQCmo91psZ2BgDFTor8SVEE5Mm1D1k3JDMhDFxzzrOtRYFPci9lskTJaBjpqWZ4E9rDTD2q/QZntCqbC3wE9uSemRQB5f8kik7vD/AD8VQXuzKladrZKkzkONCPWsXDspUitjM8HkQdOf0PsYn1CMUC1xKYbCxkg5TkEosIwGv6CoEArUrdu/4+10LVslq494mAvEItywzrluCLCnwELfW+h/m8UHoVhZ'
      end

      factory :another_deploy_key, class: 'DeployKey' do
      end
    end

    factory :ecdsa_key do
      key do
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAYicnuE46DT02Z6o9X/NqmlYG4Sp8loMVftDoGNibWFGj4sQ05py10GVEEZS0rRiOeSJj2Q7chSHklSOuLeUxY= dummy@gitlab.com"
      end
    end

    factory :dsa_key do
      key do
        "ssh-dss AAAAB3NzaC1kc3MAAACBAI5NHnRIaP9j0wJeQWsSbIHCK/UvBI9adxzL7XeCfFmO6uNjv5i2kMYBcBM3UBJk1TDEy4A7R7eRsWt3BQHevOlfqiweyoviVKAeEaBLYdTcxhP1r1Yegrka9pS2sg6LXJtdSm/UV1ve3Gmy8Al4JOR+9oGgqRDpK4T5XxOAf08FAAAAFQCj46CT1IRffz2u1Us4icO/POCLlwAAAIAguwAG2Gj8v2CRG0N8EIY0TyXIBI8X+Nokr6aDsYXEi9zDLqd1QNM3alJ9r1ARqz8VvB/rtlinoZ5ZTZl01zdwgDw50/73ufgxiBkIbeeerissJ0SOnCdbwgGbyKoImOtlA1ImTbS5uHo8vJifqmBlhNbHzU/5fuBGtvDV1JbTwwAAAIBhodvryJ55SX4wa29yOdTOgFJhlFVVoSciE4FfjBAAfmr8InzYx3ZgJ87ohNPmevnq9lC2S2eJVP5/h9mdJzrpP3jwieipxD4NazlhUEVcTRywz3b2swMbN9I+GR/dgzLkWXtkg/XTFftC8YPIgz+eQOTP7tJrutE4pOrDiSWSyg== dummy@gitlab.com"
      end
    end
  end
end
