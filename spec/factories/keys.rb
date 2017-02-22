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

    factory :ecdsa_key_256 do
      key do
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJZmkzTgY0fiCQ+DVReyH/fFwTFz0XoR3RUO0u+199H19KFw7mNPxRSMOVS7tEtONj3Q7FcZXfqthHvgAzDiHsc= dummy@gitlab.com"
      end
    end

    factory :dsa_key_2048 do
      key do
        "ssh-dss AAAAB3NzaC1kc3MAAAEBAO/3/NPLA/zSFkMOCaTtGo+uos1flfQ5f038Uk+GY9AeLGzX+Srhw59GdVXmOQLYBrOt5HdGwqYcmLnE2VurUGmhtfeO5H+3p5pGJbkS0GxpYH1HRO9lWsncF3Hh1w4lYsDjkclDiSTdfTuN8F4Kb3DXNnVSCieeonp+B25F/CXagyTQ/pvNmHFeYgGCVdnBtFdi+xfxaZ8NKdPrGggzokbKHElDZQ4Xo5EpdcyLajgM7nB2r2RzOrmeaevKi5lV68ehRa9Yyrb7vxvwiwBwOgqR/mnN7Gnaq1jUdmJY+ct04Qwx37f5jvhv5gA4U40SGMoiHM8RFIN7Ksz0jsyX73MAAAAVALRWOfjfzHpK7KLz4iqDvvTUAevJAAABAEa9NZ+6y9iQ5erGsdfLTXFrhSefTG0NhghoO/5IFkSGfd8V7kzTvCHaFrcfpEA5kP8tpoeOG0TASB6tgGOxm1Bq4Wncry5RORBPJlAVpDGRcvZ931ddH7IgltEInS6za2uH6F/1M1QfKePSLr6xJ1ZLYfP0Og5KTp1x6yMQvfwV0a+XdA+EPgaJWLWp/pWwKWa0oLUgjsIHMYzuOGh5c708uZrmkzqvgtW2NgXhcIroRgynT3IfI2lP2rqqb3uuuE/qH5UCUFO+Dc3HnAFNeQDT/M25AERdPYBAY5a+iPjIgO+jT7BfmfByT+AZTqZySrCyc7nNZL3YgGLK0l6A1GgAAAEBAN9FpFOdIXE+YEZhKl1vPmbcn+b1y5zOl6N4x1B7Q8pD/pLMziWROIS8uLzbaZ0sMIWezHIkxuo1iROMeT+jtCubn7ragaN6AX7nMpxYUH9+mYZZs/fyElt6wCviVhTIzM+u7VdQsnZttOOlQfogHdL+SpeAft0DsfJjlcgQnsLlHQKv6aPqCPYUST2nE7RyW/ExPrMxLtOWt0/j8RYHbwwqvyeZqBz3ESBgrS9c5tBdBfauwYUV/E7gPLOU3OZFw9ue7o+zwzoTZqW6Xouy5wtWvSLQSLT5XwOslmQz8QMBxD0AQyDfEFGsBCWzmbTgKv9uqrBjubsSTaja+Cf9kMo== dummy@gitlab.com"
      end
    end
  end
end
