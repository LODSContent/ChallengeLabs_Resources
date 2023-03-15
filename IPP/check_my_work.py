
import sys
import io
import food

task_number = 0

# read task number
try:
    task_number = sys.argv[1]
except:
    print('Incorrect usage!')
    print('Execute this command with an integer as the first argument which'
    ' specifies the requirement which validation is being requested for.')

def capture_stdout():
    # Memorize the default stdout stream
    old_stdout = sys.stdout 
    sys.stdout = buffer = io.StringIO()
    return old_stdout, buffer

def reassign_default_stdout(old_stdout, buffer):
    # Put the old stream back in place
    sys.stdout = old_stdout 
    # Return a str containing the entire contents of the buffer.
    whatWasPrinted = buffer.getvalue()
    return whatWasPrinted

if task_number == '1':
    menu_is_set = isinstance(food.menu, set)
    balances_is_dict = isinstance(food.balances, dict)
    meals_ordered_is_list = isinstance(food.meals_ordered, list)
    if menu_is_set:
        print('You have successfully assigned menu to a set')
    else:
        print('You have NOT assigned the most appropriate data structure to menu')
    if balances_is_dict:
        print('You have successfully assigned balances to a dict')
    else:
        print('You have NOT assigned the most appropriate data structure to balances')
    if meals_ordered_is_list:
        print('You have successfully assigned meals_ordered to a list')
    else:
        print('You have NOT assigned the most appropriate data structure to meals_ordered')
    expected_menu = { food.meal1, food.meal2, food.meal3, food.meal4, food.meal5 }
    if expected_menu == food.menu:
        print('You have successfully added the correct data to menu')
    else:
        print('You have NOT correctly added the meals to the menu')
    expected_balances = {
        1: food.student1,
        2: food.student2,
        3: food.student3,
        4: food.student4,
        5: food.student5,
        6: food.student6,
        7: food.student7,
        8: food.student8
    }
    if expected_balances == food.balances:
        print('You have successfully added the correct data to balances')
    else:
        print('You have NOT correctly added the student accounts to balances')
if task_number == '2':
    expected_output = (
        'WARNING: student #4 has a low balance of 1.05\n'
        'WARNING: student #6 has a low balance of 5.65\n'
    )
    capture_variables = capture_stdout()
    food.check_all_balances()
    actual_output = capture_variables[1].getvalue()
    reassign_default_stdout(capture_variables[0], capture_variables[1])
    if expected_output == actual_output:
        print('You have successfully iterated through balances to warn students with a low balance')
    else:
        print('You have NOT correctly iterated through balances to warn students with a low balance')
if task_number == '3':
    expected_meal1 = food.meal1
    actual_meal1 = food.find_meal(1)
    expected_meal_none = None
    actual_meal_none = food.find_meal(6)
    if expected_meal1 == actual_meal1 and expected_meal_none == actual_meal_none:
        print('You have successfully written the find_meal() function')
    else:
        print('You have NOT correctly written the find_meal() function')
if task_number == '4':
    expected_meal = food.meal4
    actual_meal = food.checkout(1, 4)
    if expected_meal == actual_meal:
        print('You have successfully returned the correct meal when the student has a high enough balance')
    else:
        print('You have NOT returned the correct meal when the student has a high enough balance')
    actual_meal_in_meals_ordered = food.meals_ordered[len(food.meals_ordered) - 1]
    if expected_meal == actual_meal_in_meals_ordered:
        print('You have successfully added the correct meal to meals_ordered when the student has a high enough balance')
    else:
        print('You have NOT added the correct meal to meals_ordered when the student has a high enough balance')
    expected_student1_updated_balance = 51.75
    actual_student1_updated_balance = food.balances[1][1]
    if expected_student1_updated_balance == actual_student1_updated_balance:
        print('You have successfully updated the student\'s balance whenever they order lunch')
    else:
        print('You have NOT correctly updated the student\'s balance whenever they order lunch')
    expected_meal_low_balance = 'peanut butter and jelly sandwich'
    actual_meal_low_balance = food.checkout(4, 1)
    if expected_meal_low_balance == actual_meal_low_balance:
        print('You have successfully returned the correct meal when the student\'s balance is too low')
    else:
        print('You have NOT returned the correct meal when the student\'s balance is too low')
    actual_meal_in_meals_ordered_low_balance = food.meals_ordered[len(food.meals_ordered) - 1]
    if expected_meal_low_balance == actual_meal_in_meals_ordered_low_balance:
        print('You have successfully added the correct meal to meals_ordered when the student\'s balance is too low')
    else:
        print('You have NOT added the correct meal to meals_ordered when the student\'s balance is too low')
